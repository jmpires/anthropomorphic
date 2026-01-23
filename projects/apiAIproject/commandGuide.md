## Recommended CLI runs

# Real behavior (no debug)
./nt.sh en0 | jq .                      # This will typically print nothing unless you truly exceed 10MB/s (10240 KB/s).

# Force a real “breach” for testing
THRESHOLD_KBPS=5 ./nt.sh en0 | jq .     # Lower the threshold temporarily and generate traffic:

# If that still doesn’t trigger reliably, run traffic in another terminal
curl -L https://speed.hetzner.de/100MB.bin -o /dev/null         
THRESHOLD_KBPS=5 ./nt.sh en0 | jq .

# AI_COOLDOWN_SECS=900 THRESHOLD_KBPS=5 ./nt.sh en0 | jq .
AI_COOLDOWN_SECS=900 THRESHOLD_KBPS=5 ./nt.sh en0 | jq .

#
curl -L https://speed.hetzner.de/100MB.bin -o /dev/null 
DEBUG_ALWAYS_OUTPUT=1 ./nt.sh en0 | jq '.event.threshold_breached, .ai.insights'

curl -k -L https://speed.hetzner.de/100MB.bin -o /dev/null
THRESHOLD_KBPS=1 ./nt.sh en0 | jq '.event.threshold_breached, .ai.insights'


curl -L https://proof.ovh.net/files/100Mb.dat -o /dev/null &
for i in {1..5}; do
  DEBUG_ALWAYS_OUTPUT=1 ./nt.sh en0 | jq '.event.threshold_breached, .measurements.rx_kbps, .measurements.tx_kbps'
  sleep 1
done
wait

# Correct for REAL behavior (recommended)
curl -L https://proof.ovh.net/files/100Mb.dat -o /dev/null &
for i in {1..5}; do
  THRESHOLD_KBPS=500 ./nt.sh en0 | jq '.event.threshold_breached, .ai.attempted, .ai.insights'
  sleep 1
done
wait

# Correct for testing / demos
export DEBUG_ALWAYS_OUTPUT=1
export THRESHOLD_KBPS=2000
export AI_COOLDOWN_SECS=0   # testing only
curl -L https://proof.ovh.net/files/100Mb.dat -o /dev/null &
for i in {1..5}; do
  ./nt.sh en0 | jq '.event.threshold_breached, .ai.attempted, .ai.insights'
  sleep 1
done
wait




