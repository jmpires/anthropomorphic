#!/usr/bin/env bash
# nt.sh (macOS)
# Monitors network traffic via netstat. If threshold exceeded, prints ONE JSON object to stdout.
# Best-effort OpenAI enrichment: never blocks output; includes cooldown.
#
# Dependencies: bash, curl, jq, netstat, ifconfig
#
# Usage:
#   ./nt.sh en0 | jq .
#
# Test / debug:
#   THRESHOLD_KBPS=1 ./nt.sh en0 | jq .
#   THRESHOLD_KBPS=1 ./nt.sh en0; echo $?       # prints even if threshold not exceeded
#   DEBUG_ALWAYS_OUTPUT=1 ./nt.sh en0 | jq .     # prints even if threshold not exceeded
#
# Optional env vars:
#   THRESHOLD_KBPS=10240
#   AI_COOLDOWN_SECS=600
#   OPENAI_MODEL="gpt-4.1-mini"
#   OPENAI_TIMEOUT_SECS=12

set -euo pipefail

# -------------------------------------------------------------------
# User-provided snippet (as requested)
export API_KEY="$(cat chatGptApiKey.pem)"
# export DEBUG_ALWAYS_OUTPUT=1

#export ADMIN_EMAIL="admin@domain.com"
#export THRESHOLD_KBPS=10240
#export AI_COOLDOWN_SECS=600
#export OPENAI_MODEL="gpt-4.1-mini"
# -------------------------------------------------------------------

# Map API_KEY -> OPENAI_API_KEY (the API expects OPENAI_API_KEY)
export OPENAI_API_KEY="${OPENAI_API_KEY:-${API_KEY:-}}"

iface="${1:-en0}"
threshold_kbps="${THRESHOLD_KBPS:-10240}"

openai_model="${OPENAI_MODEL:-gpt-4.1-mini}"
openai_timeout_secs="${OPENAI_TIMEOUT_SECS:-12}"
cooldown_secs="${AI_COOLDOWN_SECS:-600}"
debug_always_output="${DEBUG_ALWAYS_OUTPUT:-0}"

state_file="/tmp/network_traffic_ai_${iface}.state"

# --- prerequisites
for cmd in curl jq netstat ifconfig awk; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    jq -n --arg cmd "$cmd" --arg msg "Required command not found." \
      '{status:"error", error:{message:$msg, missing_command:$cmd}}'
    exit 1
  fi
done

if ! ifconfig "$iface" >/dev/null 2>&1; then
  jq -n --arg iface "$iface" --arg msg "Network interface does not exist (macOS ifconfig check)." \
    '{status:"error", error:{message:$msg, interface:$iface}}'
  exit 1
fi

# Read Ibytes/Obytes from `netstat -I <iface> -b`
get_ib_ob() {
  netstat -I "$iface" -b 2>/dev/null | awk -v IFACE="$iface" '
    NR==1 {
      for (i=1; i<=NF; i++) {
        if ($i == "Ibytes") ib=i
        if ($i == "Obytes") ob=i
      }
      next
    }
    $1 == IFACE { iib=$ib; oob=$ob }
    END {
      if (ib == 0 || ob == 0 || iib == "" || oob == "") exit 2
      print iib, oob
    }'
}

before="$(get_ib_ob || true)"
if [[ -z "${before:-}" ]]; then
  jq -n --arg iface "$iface" --arg msg "Failed to read Ibytes/Obytes from netstat output." \
    '{status:"error", error:{message:$msg, interface:$iface}}'
  exit 1
fi

ib_before="$(awk '{print $1}' <<<"$before")"
ob_before="$(awk '{print $2}' <<<"$before")"

sleep 1

after="$(get_ib_ob || true)"
if [[ -z "${after:-}" ]]; then
  jq -n --arg iface "$iface" --arg msg "Failed to read Ibytes/Obytes from netstat output (after sample)." \
    '{status:"error", error:{message:$msg, interface:$iface}}'
  exit 1
fi

ib_after="$(awk '{print $1}' <<<"$after")"
ob_after="$(awk '{print $2}' <<<"$after")"

delta_rx=$(( ib_after - ib_before ))
delta_tx=$(( ob_after - ob_before ))

# Round up to KB/s (ceil) so small but non-zero traffic becomes 1 KB/s.
rx_kbps=$(( (delta_rx + 1023) / 1024 ))
tx_kbps=$(( (delta_tx + 1023) / 1024 ))

# Determine if this is a real threshold breach
threshold_breached=false
if [[ "$rx_kbps" -gt "$threshold_kbps" || "$tx_kbps" -gt "$threshold_kbps" ]]; then
  threshold_breached=true
fi

# If not debugging, emit only when threshold exceeded
if [[ "$debug_always_output" != "1" ]]; then
  if [[ "$threshold_breached" != "true" ]]; then
    exit 0
  fi
fi

host="$(hostname 2>/dev/null || echo unknown-host)"
ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
now_epoch="$(date +%s)"

event_json="$(
  jq -n \
    --arg host "$host" \
    --arg iface "$iface" \
    --arg ts "$ts" \
    --argjson rx "$rx_kbps" \
    --argjson tx "$tx_kbps" \
    --argjson thr "$threshold_kbps" \
    --argjson drx "$delta_rx" \
    --argjson dtx "$delta_tx" \
    --argjson ib1 "$ib_before" \
    --argjson ib2 "$ib_after" \
    --argjson ob1 "$ob_before" \
    --argjson ob2 "$ob_after" \
    --arg debug "$debug_always_output" \
    --arg breached "$threshold_breached" \
    '{
      host: $host,
      interface: $iface,
      timestamp_utc: $ts,
      rx_kbps: $rx,
      tx_kbps: $tx,
      threshold_kbps: $thr,
      threshold_breached: ($breached == "true"),
      deltas_bytes_per_sec: { rx_bytes_per_sec: $drx, tx_bytes_per_sec: $dtx },
      counters: { ibytes_before: $ib1, ibytes_after: $ib2, obytes_before: $ob1, obytes_after: $ob2 },
      platform: "macOS",
      debug_always_output: ($debug == "1")
    }'
)"

ai_attempted=false
ai_suppressed_by_cooldown=false
ai_available=true
ai_error=""
ai_payload="null"

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  ai_available=false
  ai_error="OPENAI_API_KEY (or API_KEY) not set"
fi

should_call_ai=true
if [[ -f "$state_file" ]]; then
  last_epoch="$(cat "$state_file" 2>/dev/null || echo 0)"
  if [[ "$((now_epoch - last_epoch))" -lt "$cooldown_secs" ]]; then
    should_call_ai=false
    ai_suppressed_by_cooldown=true
  fi
fi

if [[ "$ai_available" == "true" && "$should_call_ai" == "true" ]]; then
  ai_attempted=true

  # Tightened prompt: explicitly separate "real breach" vs "debug/simulation"
  prompt_text="$(
    jq -nr --arg event "$event_json" '
      "You will receive an event JSON with fields threshold_breached and debug_always_output.\n" +
      "Rules:\n" +
      "- If threshold_breached=true: treat as a real high-traffic incident. Do NOT frame it as a false positive or suggest raising the threshold as a primary mitigation.\n" +
      "- If threshold_breached=false: this is a debug/simulation run; clearly label guidance as simulation-oriented and you MAY comment on threshold tuning.\n" +
      "- Do not invent host-specific facts; base guidance only on the event.\n\n" +
      "Return output matching the required schema.\n\nEvent JSON:\n\($event)"
    '
  )"

  request_body="$(
    jq -n \
      --arg model "$openai_model" \
      --arg prompt "$prompt_text" \
      '{
        model: $model,

        text: {
          format: {
            type: "json_schema",
            strict: true,
            name: "network_traffic_insights",
            schema: {
              type: "object",
              additionalProperties: false,
              properties: {
                likely_causes: { type: "array", items: { type: "string" }, minItems: 1, maxItems: 3 },
                immediate_checks: { type: "array", items: { type: "string" }, minItems: 1, maxItems: 8 },
                quick_mitigations: { type: "array", items: { type: "string" }, minItems: 1, maxItems: 6 },
                collect_next_time: { type: "array", items: { type: "string" }, minItems: 1, maxItems: 6 },
                confidence: { type: "string", enum: ["low","medium","high"] }
              },
              required: ["likely_causes","immediate_checks","quick_mitigations","collect_next_time","confidence"]
            }
          }
        },

        input: [
          {
            role: "system",
            content: [
              { type: "input_text", text: "You are an SRE assistant. Provide concise, actionable triage guidance for network-traffic threshold alerts." }
            ]
          },
          {
            role: "user",
            content: [
              { type: "input_text", text: $prompt }
            ]
          }
        ]
      }'
  )"

  api_resp="$(
    curl -sS --max-time "$openai_timeout_secs" \
      https://api.openai.com/v1/responses \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d "$request_body" \
    || true
  )"

  output_text="$(
    printf '%s' "$api_resp" | jq -r '
      ([.output[]?
        | select(.type=="message")
        | .content[]?
        | select(.type=="output_text")
        | .text] | join("\n")) // empty
    ' 2>/dev/null || true
  )"

  if [[ -n "$output_text" ]]; then
    if printf '%s' "$output_text" | jq -e . >/dev/null 2>&1; then
      ai_payload="$(printf '%s' "$output_text" | jq -c .)"
      printf '%s' "$now_epoch" > "$state_file" 2>/dev/null || true
    else
      ai_error="AI output was not valid JSON (unexpected)"
    fi
  else
    ai_error="$(printf '%s' "$api_resp" | jq -r '.error.message // "AI request failed (no error message)"' 2>/dev/null || echo "AI request failed")"
  fi
fi

jq -n \
  --arg status "alert" \
  --arg host "$host" \
  --arg iface "$iface" \
  --arg ts "$ts" \
  --argjson rx "$rx_kbps" \
  --argjson tx "$tx_kbps" \
  --argjson thr "$threshold_kbps" \
  --argjson event "$event_json" \
  --argjson ai_attempted "$ai_attempted" \
  --argjson ai_suppressed_by_cooldown "$ai_suppressed_by_cooldown" \
  --argjson ai_available "$ai_available" \
  --arg ai_error "$ai_error" \
  --argjson ai_payload "$( [[ "$ai_payload" == "null" ]] && echo "null" || printf '%s' "$ai_payload" )" \
  '{
    status: $status,
    event_type: "network_traffic_threshold_breach",
    host: $host,
    interface: $iface,
    timestamp_utc: $ts,
    measurements: { rx_kbps: $rx, tx_kbps: $tx, threshold_kbps: $thr },
    event: $event,
    ai: {
      attempted: $ai_attempted,
      available: $ai_available,
      suppressed_by_cooldown: $ai_suppressed_by_cooldown,
      error: (if $ai_error == "" then null else $ai_error end),
      insights: $ai_payload
    }
  }'