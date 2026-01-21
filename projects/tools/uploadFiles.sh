#!/bin/bash
# Script name: uploadFiles.sh
# Description: This script uploads files to a specific EC2 instance using scp
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)	:v20260108.v20260120(6)

# For debugging purposes
# set -x

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

# --- Cross-platform timeout helper ---
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_CMD="gtimeout"
else
  error "timeout command not found. Install coreutils (e.g., 'brew install coreutils' on macOS)."
fi

command -v jq >/dev/null || error "jq not found (install with 'sudo apt install jq' or 'brew install jq')"

# --- Argument validation ---
if [[ $# -ne 3 ]]; then
  error "Usage: $0 <key-file-path> <ec2-public-ip> <local-file-path>\n\nExample: $0 ./my-key.pem 1.2.3.4 ./config.yaml"
fi

KEY_FILE="$1"
EC2_IP="$2"
LOCAL_FILE="$3"

if [[ ! -f "$KEY_FILE" ]]; then
  error "SSH key not found: $KEY_FILE"
fi
chmod 600 "$KEY_FILE" >/dev/null 2>&1

if [[ ! -f "$LOCAL_FILE" ]]; then
  error "Local file not found: $LOCAL_FILE"
fi

log "Target IP: $EC2_IP"

# --- Test SSH ---
log "Testing SSH connectivity to $EC2_IP..."
if ! "$TIMEOUT_CMD" 12 ssh -i "$KEY_FILE" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -o IdentitiesOnly=yes \
    "ubuntu@$EC2_IP" exit 2>&1; then
  error "SSH test failed. Check key, security groups, instance status, or try manually: ssh -i $KEY_FILE ubuntu@$EC2_IP"
fi

# --- Upload file ---
FILE_BASENAME=$(basename "$LOCAL_FILE")
log "Uploading $LOCAL_FILE to remote host..."
scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$LOCAL_FILE" "ubuntu@$EC2_IP:/home/ubuntu/"

log "File uploaded successfully to: /home/ubuntu/$FILE_BASENAME"