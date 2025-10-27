#!/bin/bash
# Script name: cleanupInstance.sh
# Description: This script automates the cleanup of AWS resources associated with a specific EC2 instance.
# OS supported: MacOS, Linux
# Author: Jorge Manuel Pires
# Contributors: Jorge Manuel Pires
# Initial Version.Last Updated(updates)	:v20250910.v20251016(4)

# For debugging purposes
# set -x

INSTANCE_ID="i-0fba133228ea08af5"

echo "Starting full automated cleanup for instance: $INSTANCE_ID"

# --- Auto-delete associated Key Pair (if exists) ---
KEY_NAME=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].KeyName' \
  --output text 2>/dev/null)

if [ "$KEY_NAME" != "None" ] && [ -n "$KEY_NAME" ]; then
  echo "Auto-deleting key pair: $KEY_NAME"
  aws ec2 delete-key-pair --key-name "$KEY_NAME" && echo "Key pair '$KEY_NAME' deleted."
else
  echo "No key pair associated with instance."
fi

# --- Terminate Instance ---
echo "Terminating instance $INSTANCE_ID..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID >/dev/null

# --- Wait for Termination (Highly Recommended) ---
echo "⏳ Waiting for instance to fully terminate..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

# --- Delete Attached EBS Volumes ---
echo "Deleting attached EBS volumes..."
VOLUMES=$(aws ec2 describe-volumes \
  --filters Name=attachment.instance-id,Values=$INSTANCE_ID \
  --query 'Volumes[*].VolumeId' --output text)

for vol in $VOLUMES; do
  if [ -n "$vol" ]; then
    echo "Deleting volume: $vol"
    aws ec2 delete-volume --volume-id $vol >/dev/null && echo "✅ Volume $vol deleted."
  fi
done

# --- Delete Network Interfaces (ENIs) ---
echo "🗑️  Deleting network interfaces (ENIs)..."
ENIS=$(aws ec2 describe-network-interfaces \
  --filters Name=attachment.instance-id,Values=$INSTANCE_ID \
  --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text)

for eni in $ENIS; do
  if [ -n "$eni" ]; then
    echo "Deleting ENI: $eni"
    aws ec2 delete-network-interface --network-interface-id $eni >/dev/null && echo "✅ ENI $eni deleted."
  fi
done

# --- STEP 6: Release Elastic IPs ---
echo "Releasing Elastic IPs..."
ALLOCATION_IDS=$(aws ec2 describe-addresses \
  --filters Name=instance-id,Values=$INSTANCE_ID \
  --query 'Addresses[*].AllocationId' --output text)

for alloc_id in $ALLOCATION_IDS; do
  if [ -n "$alloc_id" ]; then
    echo "Releasing Elastic IP with Allocation ID: $alloc_id"
    aws ec2 release-address --allocation-id $alloc_id >/dev/null && echo "✅ EIP $alloc_id released."
  fi
done

# --- Delete Security Groups (AWS will block if in use) ---
echo "Attempting to delete attached Security Groups (safe — AWS blocks if shared)..."
SG_IDS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].SecurityGroups[*].GroupId' --output text)

for sg in $SG_IDS; do
  if [ -n "$sg" ]; then
    echo "Attempting to delete Security Group: $sg"
    if aws ec2 delete-security-group --group-id $sg >/dev/null 2>&1; then
      echo "Security Group $sg deleted."
    else
      echo "Could not delete Security Group $sg (likely still in use by other resources)."
    fi
  fi
done

echo "FULL CLEANUP COMPLETE FOR INSTANCE: $INSTANCE_ID"