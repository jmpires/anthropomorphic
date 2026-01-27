#!/usr/bin/env bash
set -euo pipefail

API_KEY="$(tr -d ' \n\r' < perplexityApiKey.pem)"

if [[ -z "${API_KEY:-}" ]]; then
  echo "ERROR: API_KEY is not set"
  exit 1
fi

INPUT_FILE="${1:-input.json}"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "ERROR: Input file not found: $INPUT_FILE"
  exit 1
fi

jq -e . "$INPUT_FILE" >/dev/null

REQUEST_JSON="$(jq -n --argjson incident "$(cat "$INPUT_FILE")" '
{
  model: "sonar-pro",
  messages: [
    {
      role: "system",
      content: "You are an SRE assistant. Analyze incidents and return concise, actionable output."
    },
    {
      role: "user",
      content: "Analyze this incident JSON and provide: (1) likely causes, (2) immediate checks, (3) mitigations.\n\nIncident JSON:\n\($incident | tostring)"
    }
  ]
}
')"

curl -sS https://api.perplexity.ai/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "$REQUEST_JSON" \
  | jq -r '.choices[0].message.content'