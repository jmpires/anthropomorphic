#!/bin/bash
# Script name: showClusterInfo.sh
# Description: Display cluster info from Terraform output OR live AWS EC2 instances
#              Detects stale state (including IP changes after stop/start) and falls back to AWS CLI
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)	:v20251008.v20251016(3)

clear
set -e

TERRAFORM_OUTPUT_KEY="instance_summary"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }

# Check dependencies
command -v jq >/dev/null || { echo "jq not found"; exit 1; }

# Try Terraform first and validate freshness (IDs + IPs)
USE_TF=false
TF_OUTPUT=""
if command -v terraform >/dev/null 2>&1; then
  TF_OUTPUT=$(terraform output -json "$TERRAFORM_OUTPUT_KEY" 2>/dev/null || echo "")
  if [[ -n "$TF_OUTPUT" && "$TF_OUTPUT" != "null" && "$TF_OUTPUT" != "{}" ]]; then
    USE_TF=true
    
    # Extract ID + Public IP pairs from Terraform
    TF_DATA=$(echo "$TF_OUTPUT" | jq -r '.instances[] | "\(.id)\t\(.public_ip)"' | sort)
    
    if ! command -v aws >/dev/null 2>&1; then
      log "AWS CLI not found — using Terraform output without validation"
    else
      REGION=$(echo "$TF_OUTPUT" | jq -r '.region.name // "us-east-1"')
      # Get current ID + Public IP pairs from AWS
      CURRENT_DATA_RAW=$(aws ec2 describe-instances \
        --region "$REGION" \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].[InstanceId, PublicIpAddress]' \
        --output text 2>/dev/null)

      if [[ -z "$CURRENT_DATA_RAW" || "$CURRENT_DATA_RAW" == "None" ]]; then
        USE_TF=false
      else
        # Format as ID<tab>IP and sort
        CURRENT_DATA=$(echo "$CURRENT_DATA_RAW" | tr '\t' '\n' | paste - - | sort)
        # Compare full state
        if ! diff -q <(echo "$TF_DATA") <(echo "$CURRENT_DATA") >/dev/null 2>&1; then
          USE_TF=false
        fi
      fi
    fi
  fi
fi

if [[ "$USE_TF" == "true" ]]; then
  log "Using Terraform state (verified as current)"
  REGION=$(echo "$TF_OUTPUT" | jq -r '.region.name // "unknown"')
else
  log "Using live AWS EC2 data (via aws ec2 describe-instances)"
  command -v aws >/dev/null || { echo "AWS CLI not found"; exit 1; }
  REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")

  # Get raw instance data
  RAW_INSTANCES=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[]' \
    --output json)

  # Build synthetic output in a safe way
  {
    echo "{"
    echo "  \"region\": {\"name\": \"$REGION\"},"
    echo "  \"public_ips\": ["
    echo "$RAW_INSTANCES" | jq -r '.[] | select(.PublicIpAddress != null) | .PublicIpAddress' | sed 's/.*/    "&"/' | paste -sd ',' -
    echo "  ],"
    echo "  \"instances\": {"

    FIRST=true
    echo "$RAW_INSTANCES" | jq -c '.[]' | while read -r inst; do
      ID=$(echo "$inst" | jq -r '.InstanceId')
      IP=$(echo "$inst" | jq -r '.PublicIpAddress // "N/A"')
      
      # Extract Name tag
      NAME=$(echo "$inst" | jq -r '.Tags[]? | select(.Key == "Name") | .Value' 2>/dev/null | head -n1)
      if [[ -z "$NAME" || "$NAME" == "null" ]]; then
        NAME="instance-${ID:0:8}"
      fi

      # Extract Role tag
      ROLE=$(echo "$inst" | jq -r '.Tags[]? | select(.Key == "Role") | .Value' 2>/dev/null | head -n1)
      if [[ -z "$ROLE" || "$ROLE" == "null" ]]; then
        ROLE="worker"
      fi

      SSH_CMD="ssh -i ./k8ClusterKeyPair.pem ubuntu@$IP"

      if [[ "$FIRST" == "true" ]]; then
        FIRST=false
      else
        echo ","
      fi
      printf '    "%s": {\n' "$NAME"
      printf '      "id": "%s",\n' "$ID"
      printf '      "public_ip": "%s",\n' "$IP"
      printf '      "role": "%s",\n' "$ROLE"
      printf '      "ssh_command": "%s"\n' "$SSH_CMD"
      printf "    }"
    done
    echo
    echo "  }"
    echo "}"
  } > /tmp/synthetic_output.json

  TF_OUTPUT=$(cat /tmp/synthetic_output.json)
  rm -f /tmp/synthetic_output.json
fi

# Display region
echo -e "${BLUE}| Region:${NC} $REGION"
echo

# Display instances
echo -e "${BLUE}| Instances:${NC}"
echo "------------------------------------------------------------------"
echo -e "NAME       ROLE             PUBLIC IP       INSTANCE ID"
echo "------------------------------------------------------------------"

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