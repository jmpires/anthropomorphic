#!/bin/bash
# Script name: showClusterInfo.sh
# Description: Simple script to display cluster info from Terraform output
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)	:v20251008.v20251016(3)

# For debugging purposes
# set -x

set -e

TERRAFORM_OUTPUT_KEY="instance_summary"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }

# Check dependencies
command -v terraform >/dev/null || { echo "Terraform not found"; exit 1; }
command -v jq >/dev/null || { echo "jq not found (install with 'brew install jq' or 'sudo apt install jq')"; exit 1; }

# Fetch output
log "Reading Terraform output: $TERRAFORM_OUTPUT_KEY"
TF_OUTPUT=$(terraform output -json "$TERRAFORM_OUTPUT_KEY" 2>/dev/null)

if [[ -z "$TF_OUTPUT" ]]; then
  echo "Terraform output '$TERRAFORM_OUTPUT_KEY' is empty. Run 'terraform apply' first."
  exit 1
fi

# Extract region
REGION=$(echo "$TF_OUTPUT" | jq -r '.region.name // "unknown"')
echo -e "${BLUE}| Region:${NC} $REGION"
echo

# Extract and display instances
echo -e "${BLUE}| Instances:${NC}"
echo "------------------------------------------------------------------"
echo -e "NAME       ROLE             PUBLIC IP       INSTANCE ID"
echo "------------------------------------------------------------------"

# Loop through each instance
echo "$TF_OUTPUT" | jq -r '.instances | to_entries[] | "\(.key)\t\(.value.role)\t\(.value.public_ip)\t\(.value.id)"' | while IFS=$'\t' read -r name role ip id; do
  printf "%-10s %-16s %-15s %s\n" "$name" "$role" "$ip" "$id"
done

echo
echo -e "${BLUE}| SSH Commands:${NC}"
echo "------------------------------------------------------------------"
echo "$TF_OUTPUT" | jq -r '.instances | to_entries[] | "\(.value.ssh_command)"' | while read -r cmd; do
  echo "$cmd"
done

echo
echo -e "${BLUE}| Summary:${NC}"
INSTANCE_COUNT=$(echo "$TF_OUTPUT" | jq '[.instances[]] | length')
echo "Total instances: $INSTANCE_COUNT"
echo "Public IPs: $(echo "$TF_OUTPUT" | jq -r '.public_ips | join(", ")')"