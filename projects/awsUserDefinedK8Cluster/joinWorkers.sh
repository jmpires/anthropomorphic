#!/bin/bash
# Script name: joinWorkers.sh
# Description: This script automates the joining of worker node(s) to the control plane across AWS EC2 instances.
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)	:v20251008.v20251016(4)

# For debugging purposes
# set -x

set -e

# --- Configuration ---
KEY_FILE="./k8ClusterKeyPair.pem"
REMOTE_USER="ubuntu"
TERRAFORM_OUTPUT_KEY="instance_summary"
CONTROL_PLANE_NODE="node-0"

# --- Colors (only if terminal supports it) ---
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

# --- Dependencies ---
command -v terraform >/dev/null || error "terraform not found in PATH"
command -v jq >/dev/null || error "jq not found (install: 'brew install jq' or 'sudo apt install jq')"

[[ -f "$KEY_FILE" ]] || error "SSH key not found: $KEY_FILE"
chmod 600 "$KEY_FILE" >/dev/null 2>&1

# --- Helper: safely run SSH with timeout ---
run_ssh() {
  local host="$1"
  shift
  # Use 'timeout' on Linux, 'gtimeout' on macOS (from coreutils)
  local timeout_cmd="timeout"
  if ! command -v timeout >/dev/null 2>&1; then
    if command -v gtimeout >/dev/null 2>&1; then
      timeout_cmd="gtimeout"
    else
      error "Install 'timeout': brew install coreutils (macOS) or use Linux"
    fi
  fi
  "$timeout_cmd" 15 ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$host" "$@"
}

# --- Extract 'instances' from Terraform output ---
log "Reading Terraform output..."
TF_RAW=$(terraform output -json "$TERRAFORM_OUTPUT_KEY" 2>/dev/null)
INSTANCES_JSON=$(echo "$TF_RAW" | jq -r '.instances // empty' 2>/dev/null)

if [[ -z "$INSTANCES_JSON" || "$INSTANCES_JSON" == "null" || "$INSTANCES_JSON" == "empty" ]]; then
  error "Failed to extract '.instances' from Terraform output '$TERRAFORM_OUTPUT_KEY'"
fi

# --- Get control-plane public IP ---
CP_IP=$(echo "$INSTANCES_JSON" | jq -r ".[\"$CONTROL_PLANE_NODE\"].public_ip // empty")
if [[ -z "$CP_IP" || "$CP_IP" == "null" ]]; then
  error "Control-plane node '$CONTROL_PLANE_NODE' not found or has no public IP"
fi
log "Control-plane IP: $CP_IP"

# --- Wait briefly and fetch join command ---
log "Fetching kubeadm join command from control plane..."
JOIN_CMD=""
retries=5
while [[ -z "$JOIN_CMD" && $retries -gt 0 ]]; do
  JOIN_CMD=$(run_ssh "$REMOTE_USER@$CP_IP" "sudo kubeadm token create --print-join-command 2>/dev/null") || true
  if [[ -z "$JOIN_CMD" ]]; then
    warn "Join command not ready. Retrying in 5s... ($((retries - 1)) left)"
    sleep 5
    ((retries--))
  fi
done

[[ -n "$JOIN_CMD" ]] || error "Failed to retrieve join command after retries. Is kubeadm init complete?"

log "Join command retrieved."

# --- Discover all valid node names: node-<digits> ---
# Use while-read loop for maximum portability (avoids mapfile)
ALL_NODES=()
while IFS= read -r node_name; do
  [[ -n "$node_name" ]] && ALL_NODES+=("$node_name")
done < <(echo "$INSTANCES_JSON" | jq -r 'keys[] | select(test("^node-[0-9]+$"))')

# --- Filter out control plane ---
WORKER_NODES=()
for node in "${ALL_NODES[@]}"; do
  if [[ "$node" != "$CONTROL_PLANE_NODE" ]]; then
    WORKER_NODES+=("$node")
  fi
done

if [[ ${#WORKER_NODES[@]} -eq 0 ]]; then
  log "No worker nodes found (only control plane detected). Nothing to join."
  exit 0
fi

log "Discovered ${#WORKER_NODES[@]} worker node(s): ${WORKER_NODES[*]}"

# --- Join each worker ---
for NODE in "${WORKER_NODES[@]}"; do
  WORKER_IP=$(echo "$INSTANCES_JSON" | jq -r ".[\"$NODE\"].public_ip // empty")
  if [[ -z "$WORKER_IP" || "$WORKER_IP" == "null" ]]; then
    warn "Skipping $NODE: no public IP"
    continue
  fi

  log "Joining worker: $NODE ($WORKER_IP)"
  run_ssh "$REMOTE_USER@$WORKER_IP" "sudo $JOIN_CMD"
  log "$NODE successfully joined!"
done

log "All workers joined! Verify with:"
log "ssh -i \"$KEY_FILE\" $REMOTE_USER@$CP_IP 'kubectl get nodes'"