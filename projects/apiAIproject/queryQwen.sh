#!/usr/bin/env bash
set -euo pipefail

export ANTHROPIC_API_KEY="$(cat qwenApiKey.pem)"

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "ERROR: ANTHROPIC_API_KEY is not set"
  exit 1
fi

INPUT_FILE="${1:-input.json}"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "ERROR: Input file not found: $INPUT_FILE"
  exit 1
fi

# Validate that the file is valid JSON
jq -e . "$INPUT_FILE" >/dev/null

# Get the incident data
INCIDENT_DATA="$(cat "$INPUT_FILE")"

# Build correct request JSON for Anthropic API
REQUEST_JSON="$(jq -n --arg incident_data "$INCIDENT_DATA" '
{
  model: "claude-3-sonnet-20240229",
  max_tokens: 1024,
  temperature: 0,
  system: "You are an SRE assistant. Analyze incidents and return concise, actionable output.",
  messages: [
    {
      role: "user",
      content: ("Analyze this incident JSON and provide: (1) likely causes, (2) immediate checks, (3) mitigations.\n\nIncident data: " + $incident_data)
    }
  ]
}
')"

curl -sS https://api.anthropic.com/v1/messages \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d "$REQUEST_JSON"