
export API_KEY="$(cat aiApiKey.pem)"

# 4 ChatGPT
./queryChatGpt.sh input.json
./queryChatGpt.sh input.json | jq -r '.output[0].content[0].text'

# 4 Gemini
./queryGemini.sh input.json

curl "https://generativelanguage.googleapis.com/v1beta/models?key=$(cat geminiApiKey.pem)"          # Model that we have access

# 4 Preplexity
./queryPreplexity.sh input.json
./queryPreplexity.sh input.json | jq -r '.output[0].content[0].text'

# 4 Qwen - currently API is paid !!!!
./queryQwen.sh input.json