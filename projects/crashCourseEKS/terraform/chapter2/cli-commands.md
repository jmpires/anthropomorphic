# 📘 **EKS Crash Course - CLI Commands**


### 📋 Code Structure

# Set environment variables

```bash
export AWS_REGION="us-east-1"
export CLUSTER_NAME="dev-eks-cluster"
```

# Cluster Version and Status

```bash
aws eks describe-cluster \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --query "cluster.{status:status, version:version, endpoint:endpoint}" \
  --output table
```

# Identify managed nodegroups vs self-managed - (if this returns one or more names, you're on managed nodegroups)

```bash
aws eks list-nodegroups \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --output text \
  --query "nodegroups"
```

# List installed EKS add-ons (EKS-managed add-ons)

```bash
aws eks list-addons \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --output text
```

# Control-plane upgrade

```bash
aws eks update-cluster-version \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --kubernetes-version "1.29"
```

# Wait until the control plane is ACTIVE again

```bash
# Wait until the control plane is ACTIVE again
aws eks wait cluster-active \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"
clear; echo "✅ Cluster $CLUSTER_NAME is now ACTIVE"
```

# Confirm cluster status and version

```bash
aws eks describe-cluster \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --query "cluster.{status:status, version:version}" \
  --output table
```

# Monitor the control plane upgrade in detail

```bash
export UPDATE_ID=$(aws eks list-updates \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'updateIds[0]' \
  --output text)

aws eks describe-update \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --update-id "$UPDATE_ID"
```

# Get nodegroup names

```bash
NODEGROUPS=$(aws eks list-nodegroups \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --query "nodegroups[]" \
  --output text)

echo "$NODEGROUPS"
```

# Validate cluster and nodegroup version

```bash
aws eks describe-cluster \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --query "cluster.version"

aws eks describe-nodegroup \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "$NG" \
  --query "nodegroup.version"
```

# Upgrade cycle for the nodes

```bash
for NG in $NODEGROUPS; do
  aws eks update-nodegroup-version \
    --region "$AWS_REGION" \
    --cluster-name "$CLUSTER_NAME" \
    --nodegroup-name "$NG" \
    --kubernetes-version "1.29" \
    --no-force
done
```
# Validating progress

```bash
ID=$(aws eks list-updates \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --nodegroup-name "$NG" \
  --query "updateIds[-1]" \
  --output text)

aws eks describe-update \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --nodegroup-name "$NG" \
  --update-id "$ID"
```

# Monitor the nodegroups upgrade

```bash
NODEGROUPS=$(aws eks list-nodegroups \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --query "nodegroups[]" \
  --output text)

echo "$NODEGROUPS"

for NG in $NODEGROUPS; do
  aws eks describe-nodegroup \
    --region "$AWS_REGION" \
    --cluster-name "$CLUSTER_NAME" \
    --nodegroup-name "$NG" \
    --query "nodegroup.{status:status,version:version,releaseVersion:releaseVersion}" \
    --output table
done
```

# List installed EKS add-ons (EKS-managed add-ons)

```bash
aws eks list-addons \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --output text
```

# Optional: Manual Drain Sequence(Advanced Operations)

```bash
# Refresh kubeconfig context
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

# List all nodes with detailed information
kubectl get nodes -o wide

# Optionally drain one node at a time:
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=60 \
  --timeout=10m
```

# Post-Upgrade Validation (Minimum Acceptance Criteria)

```bash
aws eks describe-cluster \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --query "cluster.version" \
  --output text

aws eks list-nodegroups \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --output text
```

# Refreshing context

```bash
aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"
```

# Validate cluster components

```bash
kubectl config view --minify --raw | grep server:
kubectl get --raw=/healthz
kubectl version
kubectl get nodes
kubectl -n kube-system get pods
```