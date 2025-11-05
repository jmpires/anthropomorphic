#!/bin/bash

set -euo pipefail

clear

# === CONFIGURE THESE ===
VPC_ID="vpc-09cc3466ba0101ed9"
SUBNETS=("subnet-0c1c58b60724ae004" "subnet-0937babbdcfcfd47e")
IGW_ID="igw-02971fb97a09b95ac"
# =======================

SUBNET_LIST=$(IFS=,; echo "${SUBNETS[*]}")

echo "🧹 Starting comprehensive cleanup for VPC: $VPC_ID"
echo "Subnets: ${SUBNETS[*]}"
echo "=================================================="

# --- 1. EC2 Instances ---
echo "➡️  [1/10] Terminating EC2 instances..."
INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=subnet-id,Values=$SUBNET_LIST" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
  --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null || echo "None")
if [ "$INSTANCES" != "None" ] && [ -n "$INSTANCES" ]; then
  echo "Terminating: $INSTANCES"
  aws ec2 terminate-instances --instance-ids $INSTANCES >/dev/null
  aws ec2 wait instance-terminated --instance-ids $INSTANCES
else
  echo "No EC2 instances found."
fi

# --- 2. NAT Gateways ---
echo -e "\n➡️  [2/10] Deleting NAT Gateways..."
NAT_GWS=$(aws ec2 describe-nat-gateways \
  --filter "Name=subnet-id,Values=$SUBNET_LIST" "Name=state,Values=pending,available" \
  --query 'NatGateways[].NatGatewayId' --output text 2>/dev/null || echo "None")
if [ "$NAT_GWS" != "None" ] && [ -n "$NAT_GWS" ]; then
  for NAT in $NAT_GWS; do
    echo "Deleting NAT Gateway: $NAT"
    aws ec2 delete-nat-gateway --nat-gateway-id "$NAT" >/dev/null
  done
  aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GWS
else
  echo "No NAT Gateways found."
fi

# --- 3. Application/Network Load Balancers (v2) ---
echo -e "\n➡️  [3/10] Deleting Application/Network Load Balancers (v2)..."
LB_ARNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerArn' --output text 2>/dev/null || echo "")
DELETED_V2=0
for ARN in $LB_ARNS; do
  LB_SUBNETS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ARN" \
    --query 'LoadBalancers[].AvailabilityZones[].SubnetId' --output text)
  for SUB in "${SUBNETS[@]}"; do
    if echo "$LB_SUBNETS" | grep -qw "$SUB"; then
      echo "Deleting ALB/NLB: $ARN"
      aws elbv2 delete-load-balancer --load-balancer-arn "$ARN" >/dev/null
      ((DELETED_V2++))
      break
    fi
  done
done
echo "Deleted $DELETED_V2 ALB/NLB(s)."

# --- 4. Classic Load Balancers (v1) ---
echo -e "\n➡️  [4/10] Deleting Classic Load Balancers (v1)..."
CLASSIC_LBS=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text 2>/dev/null || echo "")
DELETED_V1=0
for LB_NAME in $CLASSIC_LBS; do
  LB_SUBNETS=$(aws elb describe-load-balancers --load-balancer-names "$LB_NAME" \
    --query 'LoadBalancerDescriptions[].Subnets[]' --output text 2>/dev/null || echo "")
  for SUB in "${SUBNETS[@]}"; do
    if echo "$LB_SUBNETS" | grep -qw "$SUB"; then
      echo "Deleting Classic LB: $LB_NAME"
      aws elb delete-load-balancer --load-balancer-name "$LB_NAME" >/dev/null
      ((DELETED_V1++))
      break
    fi
  done
done
echo "Deleted $DELETED_V1 Classic LB(s)."

# --- 5. Lambda VPC Configs ---
echo -e "\n➡️  [5/10] Removing Lambda VPC configs..."
for SUB in "${SUBNETS[@]}"; do
  LAMBDAS=$(aws lambda list-functions \
    --query "Functions[?contains(VpcConfig.SubnetIds, \`$SUB\`)].FunctionName" --output text 2>/dev/null || echo "None")
  if [ "$LAMBDAS" != "None" ] && [ -n "$LAMBDAS" ]; then
    for FN in $LAMBDAS; do
      echo "Removing VPC config from Lambda: $FN"
      aws lambda update-function-configuration --function-name "$FN" --vpc-config SubnetIds=[],SecurityGroupIds=[] >/dev/null
    done
  fi
done
echo "Lambda cleanup initiated (ENIs may persist for minutes)."

# --- 6. RDS & Aurora ---
echo -e "\n➡️  [6/10] Checking RDS & Aurora..."
RDS_INSTANCES=$(aws rds describe-db-instances --query 'DBInstances[?DBSubnetGroup.Subnets[?SubnetIdentifier==`'"${SUBNETS[0]}"'` || SubnetIdentifier==`'"${SUBNETS[1]}"'`]].DBInstanceIdentifier' --output text 2>/dev/null || echo "None")
if [ "$RDS_INSTANCES" != "None" ] && [ -n "$RDS_INSTANCES" ]; then
  for DB in $RDS_INSTANCES; do
    echo "Deleting RDS instance: $DB"
    aws rds delete-db-instance --db-instance-identifier "$DB" --skip-final-snapshot --delete-automated-backups >/dev/null
  done
  for DB in $RDS_INSTANCES; do
    aws rds wait db-instance-deleted --db-instance-identifier "$DB" 2>/dev/null || true
  done
else
  echo "No RDS instances found."
fi

RDS_CLUSTERS=$(aws rds describe-db-clusters --query 'DBClusters[?DBSubnetGroup.Subnets[?SubnetIdentifier==`'"${SUBNETS[0]}"'` || SubnetIdentifier==`'"${SUBNETS[1]}"'`]].DBClusterIdentifier' --output text 2>/dev/null || echo "None")
if [ "$RDS_CLUSTERS" != "None" ] && [ -n "$RDS_CLUSTERS" ]; then
  for CL in $RDS_CLUSTERS; do
    echo "Deleting Aurora cluster: $CL"
    aws rds delete-db-cluster --db-cluster-identifier "$CL" --skip-final-snapshot >/dev/null
  done
  for CL in $RDS_CLUSTERS; do
    aws rds wait db-cluster-deleted --db-cluster-identifier "$CL" 2>/dev/null || true
  done
else
  echo "No Aurora clusters found."
fi

# --- 7. EFS ---
echo -e "\n➡️  [7/10] Checking EFS..."
EFS_FILESYSTEMS=$(aws efs describe-file-systems --query 'FileSystems[].FileSystemId' --output text 2>/dev/null || echo "")
EFS_DELETED=0
for FS in $EFS_FILESYSTEMS; do
  MOUNT_TARGETS=$(aws efs describe-mount-targets --file-system-id "$FS" --query 'MountTargets[?SubnetId==`'"${SUBNETS[0]}"'` || SubnetId==`'"${SUBNETS[1]}"'`].MountTargetId' --output text 2>/dev/null || echo "None")
  if [ "$MOUNT_TARGETS" != "None" ] && [ -n "$MOUNT_TARGETS" ]; then
    for MT in $MOUNT_TARGETS; do
      echo "Deleting EFS mount target: $MT"
      aws efs delete-mount-target --mount-target-id "$MT" >/dev/null
    done
    sleep 10
    aws efs delete-file-system --file-system-id "$FS" >/dev/null
    ((EFS_DELETED++))
  fi
done
if [ $EFS_DELETED -eq 0 ]; then echo "No EFS found."; else echo "EFS deleted."; fi

# --- 8. VPC Endpoints ---
echo -e "\n➡️  [8/10] Deleting VPC Endpoints..."
ENDPOINTS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --query 'VpcEndpoints[].VpcEndpointId' --output text 2>/dev/null || echo "None")
if [ "$ENDPOINTS" != "None" ] && [ -n "$ENDPOINTS" ]; then
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $ENDPOINTS >/dev/null
  echo "VPC Endpoints deleted."
else
  echo "No VPC Endpoints found."
fi

# --- 9. Elastic IPs ---
echo -e "\n➡️  [9/10] Releasing Elastic IPs..."
ALL_EIPS=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --output json 2>/dev/null || echo '{"Addresses":[]}')
EIP_DATA=$(echo "$ALL_EIPS" | jq -r --arg VPC "$VPC_ID" '
  .Addresses[]
  | select(.VpcId == $VPC)
  | select(.AssociationId != null)
  | "\(.AssociationId) \(.AllocationId)"
' 2>/dev/null || echo "")
if [ -n "$EIP_DATA" ]; then
  while read -r ASSOC ALLOC; do
    if [ -n "$ASSOC" ] && [ -n "$ALLOC" ]; then
      echo "Releasing EIP: $ALLOC"
      aws ec2 disassociate-address --association-id "$ASSOC" 2>/dev/null || true
      sleep 2
      aws ec2 release-address --allocation-id "$ALLOC" || true
    fi
  done <<< "$EIP_DATA"
else
  echo "No Elastic IPs found."
fi

# --- 10. Wait for ENI cleanup + Final deletion ---
echo -e "\n⏳ [10/10] Waiting for AWS to clean up ENIs (up to 2 minutes)..."
sleep 30

# Retry ENI cleanup every 15s for up to 2 minutes
ENIS_REMAINING=""
for attempt in {1..8}; do
  echo "CallCheck $attempt: Checking for ENIs in subnets..."
  ENIS_REMAINING=$(aws ec2 describe-network-interfaces \
    --filters "Name=subnet-id,Values=$SUBNET_LIST" \
    --query 'NetworkInterfaces[].NetworkInterfaceId' --output text 2>/dev/null || echo "None")

  if [ "$ENIS_REMAINING" = "None" ] || [ -z "$ENIS_REMAINING" ]; then
    echo "✅ No ENIs found. Proceeding to delete subnets and VPC."
    break
  else
    echo "Found ENIs: $ENIS_REMAINING — attempting deletion..."
    for eni in $ENIS_REMAINING; do
      aws ec2 delete-network-interface --network-interface-id "$eni" 2>/dev/null || true
    done
    if [ $attempt -lt 8 ]; then
      sleep 15
    fi
  fi
done

# Get all non-default SGs in VPC (dynamically)
SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>/dev/null || echo "None")

# Delete subnets
echo "➡️  Deleting subnets..."
for SUB in "${SUBNETS[@]}"; do
  aws ec2 delete-subnet --subnet-id "$SUB" && echo "✅ Deleted subnet: $SUB" || echo "❌ Failed to delete subnet: $SUB"
done

# Delete security groups (after ENIs gone)
if [ "$SGS" != "None" ] && [ -n "$SGS" ]; then
  echo "➡️  Deleting security groups..."
  for SG in $SGS; do
    aws ec2 delete-security-group --group-id "$SG" && echo "✅ Deleted SG: $SG" || echo "❌ Failed to delete SG: $SG (likely still in use)"
  done
fi

# Detach and delete IGW
echo "➡️  Deleting Internet Gateway..."
aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" 2>/dev/null || true
sleep 5
aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" 2>/dev/null && echo "✅ IGW deleted" || echo "⚠️ IGW not deleted (may be already gone)"

# Final VPC delete
echo "➡️  Deleting VPC..."
if aws ec2 delete-vpc --vpc-id "$VPC_ID" 2>/dev/null; then
  echo "🎉 SUCCESS: VPC $VPC_ID has been deleted!"
else
  echo "💥 FAILED: VPC still has dependencies."
  echo "🔍 Run this to diagnose:"
  echo "aws ec2 describe-network-interfaces --filters Name=subnet-id,Values=$SUBNET_LIST --query 'NetworkInterfaces[*].[NetworkInterfaceId,Description,Status,Groups[].GroupId]' --output table"
fi