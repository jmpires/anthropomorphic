
export OPENAI_API_KEY="$(cat aiApiKey.pem)"

./queryAI.sh input.json

./queryAI.sh input.json | jq -r '.output[0].content[0].text'
