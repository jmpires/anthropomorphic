#!/usr/bin/env bash
set -euo pipefail

# 1. Load API Key
export API_KEY="$(cat geminiApiKey.pem)"

if [[ -z "${API_KEY:-}" ]]; then
  echo "ERROR: API_KEY is not set"
  exit 1
fi

# 2. Handle Input File
INPUT_FILE="${1:-input.json}"
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "ERROR: Input file not found: $INPUT_FILE"
  exit 1
fi

# 3. Build Request for Gemini 3
REQUEST_JSON="$(jq -n --arg incident "$(cat "$INPUT_FILE")" '
{
  "contents": [{
    "parts":[{
      "text": "You are an SRE assistant. Analyze this incident JSON and provide: (1) likely causes, (2) immediate checks, (3) mitigations: \($incident)"
    }]
  }],
  "generationConfig": {
    "temperature": 0.2
  }
}
')"

echo "Sending request to Gemini 3 Flash..."

# 4. API Call using the specific model found in your list
RESPONSE=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_JSON")

# 5. Extract text or show debug error
RESULT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')

if [[ -z "$RESULT" ]]; then
  echo "--- API ERROR ---"
  echo "$RESPONSE" | jq .
else
  echo -e "\n--- SRE INCIDENT ANALYSIS ---\n"
  echo "$RESULT"
fi