#!/usr/bin/env bash
set -euo pipefail

export API_KEY="$(cat chatGptApiKey.pem)"

if [[ -z "${API_KEY:-}" ]]; then
  echo "ERROR: API_KEY is not set"
  exit 1
fi

INPUT_FILE="${1:-input.json}"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "ERROR: Input file not found: $INPUT_FILE"
  exit 1
fi

# Validate that the file is valid JSON
jq -e . "$INPUT_FILE" >/dev/null

# Build a valid request JSON (no manual escaping)
REQUEST_JSON="$(jq -n --argjson incident "$(cat "$INPUT_FILE")" '
{
  model: "gpt-4.1-mini",
  input: [
    {
      role: "system",
      content: [
        { type: "input_text", text: "You are an SRE assistant. Analyze incidents and return concise, actionable output." }
      ]
    },
    {
      role: "user",
      content: [
        { type: "input_text", text: "Analyze this incident JSON and provide: (1) likely causes, (2) immediate checks, (3) mitigations." },
        { type: "input_text", text: ($incident | tostring) }
      ]
    }
  ]
}
')"

curl -sS https://api.openai.com/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "$REQUEST_JSON"