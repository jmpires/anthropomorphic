# Update EKS-Managed Add-ons
Production-Grade Practices & Verified Execution Steps

---

## 📌 Scope

This document defines the procedure to **update EKS-managed add-ons for Kubernetes 1.29.**

**Prerequisite:** 
- Ensure the EKS Control Plane is already upgraded to 1.29 and status is ```ACTIVE```.
- Export the required environment variables in your shell session:

```bash
export AWS_REGION="<your-region>"        # e.g., us-east-1
export CLUSTER_NAME="<your-cluster-name>" # e.g., your-eks-cluster
```

**Why:**

- ```kube-proxy``` and ```CoreDNS``` are version-sensitive and must align with the control plane.
- ```VPC CNI``` is tightly coupled to networking behavior and kernel versions.
- **AWS** recommends updating add-ons before upgrading worker node groups.

# 1. Verify Installed Add-ons
Before updating, confirm which add-ons are currently managed by EKS.

```bash
# List installed EKS add-ons
aws eks list-addons \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --output text
```
⚠️ **Warning**
- Only update add-ons that appear in the list above.
- Attempting to update an add-on that is not installed or not EKS-managed will result in errors.

# 2. Check Recommended Versions
Verify the default recommended versions for Kubernetes 1.29.

```bash
aws eks describe-addon-versions \
  --region "$AWS_REGION" \
  --kubernetes-version "1.29" \
  --addon-names vpc-cni coredns kube-proxy aws-ebs-csi-driver \
  --query "addons[].{addon:addonName, versions:addonVersions[?compatibilities[?defaultVersion==`true`]].addonVersion}" \
  --output table
```

# 3. Update Core Add-ons
Execute the update for each installed add-on. Order matters: Update ```vpc-cni``` first, then ```coredns``` and ```kube-proxy```.

⚠️ **Critical Warning**
- ```--resolve-conflicts OVERWRITE``` will revert custom configuration values to EKS defaults.
- If you have customized replica counts, environment variables, or compute types, review your configuration before proceeding. For most standard clusters, this is safe.

**VPC CNI**
```bash
aws eks update-addon \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name vpc-cni \
  --resolve-conflicts OVERWRITE
```

**CoreDNS**
```bash
aws eks update-addon \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name coredns \
  --resolve-conflicts OVERWRITE
```

**kube-proxy**
```bash
aws eks update-addon \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name kube-proxy \
  --resolve-conflicts OVERWRITE
```

**EBS CSI Driver (If installed)**
```bash
aws eks update-addon \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name aws-ebs-csi-driver \
  --resolve-conflicts OVERWRITE
```

# 4. Wait for each add-on to become ACTIVE
Updates are asynchronous. Wait for each **installed add-on** to stabilize before proceeding to node group upgrades.

```bash
# Get list of installed add-ons
INSTALLED_ADDONS=$(aws eks list-addons \
  --region <aws-region> \
  --cluster-name <cluster-name> \
  --output text)

# Wait for each installed add-on to become ACTIVE
for ADDON in $INSTALLED_ADDONS; do
  echo "Waiting for $ADDON to become ACTIVE..."
  aws eks wait addon-active \
    --region <aws-region> \
    --cluster-name <cluster-name> \
    --addon-name "$ADDON"
done
```

# 5. Post Validation
Confirm all add-ons are ACTIVE

```bash
aws eks describe-addons \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --query "addons[].{addon:addonName, status:status}" \
  --output table
  ```