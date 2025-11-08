#!/bin/bash
# Script name: deployNodes.sh
# Description: This script deploys a Kubernetes node (control plane or worker) on an AWS EC2 instance by running a specified setup script remotely.
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)	:v20251008.v20251016(3)

# For debugging purposes
# set -x

# --- Configuration defaults ---
KEY_FILE="./k8ClusterKeyPair.pem"
REMOTE_USER="ubuntu"
TERRAFORM_OUTPUT_KEY="instance_summary"

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

# --- Pre-flight checks ---
command -v terraform >/dev/null || error "terraform not found in PATH"
command -v jq >/dev/null || error "jq not found (install with 'sudo apt install jq' or 'brew install jq')"

if [[ ! -f "$KEY_FILE" ]]; then
  error "SSH key not found: $KEY_FILE"
fi
chmod 600 "$KEY_FILE" >/dev/null 2>&1

# --- Argument validation ---
if [[ $# -ne 2 ]]; then
  error "Usage: $0 <node-id> <role-script>\n\nExample: $0 node-0 ./k8ControlPlane.sh"
fi

NODE_NAME="$1"
LOCAL_SCRIPT="$2"

# -- Validate node name format: must be 'node-<non-negative integer>' ---
if [[ ! "$NODE_NAME" =~ ^node-[0-9]+$ ]]; then
  error "Invalid node name: '$NODE_NAME'. Must be in format 'node-0', 'node-1', 'node-123', etc."
fi

if [[ ! -f "$LOCAL_SCRIPT" ]]; then
  error "Local script not found: $LOCAL_SCRIPT"
fi

# --- Fetch IP ---
log "Fetching IP for '$NODE_NAME' from Terraform output..."
TF_OUTPUT=$(terraform output -json "$TERRAFORM_OUTPUT_KEY" 2>/dev/null)

if [[ -z "$TF_OUTPUT" ]]; then
  error "Terraform output '$TERRAFORM_OUTPUT_KEY' is empty. Run 'terraform apply' first?"
fi

CP_IP=$(echo "$TF_OUTPUT" | jq -r ".instances[\"$NODE_NAME\"].public_ip // empty")
if [[ -z "$CP_IP" || "$CP_IP" == "null" ]]; then
  error "Failed to extract public_ip for '$NODE_NAME'. Check Terraform output structure or instance name."
fi

log "Target IP: $CP_IP"

# --- Test SSH ---
log "Testing SSH connectivity to $NODE_NAME ($CP_IP)..."
if ! "$TIMEOUT_CMD" 12 ssh -i "$KEY_FILE" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -o IdentitiesOnly=yes \
    "$REMOTE_USER@$CP_IP" exit 2>&1; then
  error "SSH test failed. Check key, security groups, instance status, or try manually: ssh -i $KEY_FILE $REMOTE_USER@$CP_IP"
fi

# --- Deploy ---
SCRIPT_BASENAME=$(basename "$LOCAL_SCRIPT")
log "Copying $LOCAL_SCRIPT to remote host..."
scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$LOCAL_SCRIPT" "$REMOTE_USER@$CP_IP:/home/$REMOTE_USER/"

log "Running script on remote host..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$REMOTE_USER@$CP_IP" \
  "chmod +x /home/$REMOTE_USER/$SCRIPT_BASENAME && \
   sudo /home/$REMOTE_USER/$SCRIPT_BASENAME 2>&1 | tee /home/$REMOTE_USER/k8s-install.log"

log "Done! Logs available on instance at: ~/k8s-install.log"