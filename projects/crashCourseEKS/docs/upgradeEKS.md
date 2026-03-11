# EKS Manual Upgrade Runbook
Production-Grade Practices & Verified Execution Steps

---

## 📌 Scope

This document defines the **mandatory operational process** for manually upgrading an **Amazon EKS cluster**, including:

- EKS Control Plane
- EKS Managed Add-ons
- EKS Managed Node Groups

This runbook is designed for **production environments** and assumes high availability requirements.

---

## 🚫 Out of Scope

- Terraform-driven upgrades (covered separately)
- Self-managed Kubernetes clusters
- Blue/green cluster migration strategy

---

# 🔒 Non-Negotiable Rules

## 1️⃣ Upgrade One Minor Version at a Time

EKS only supports incremental minor version upgrades.

**Example:**

```
1.28 → 1.29 → 1.30 → 1.31
```

Skipping minor versions is not supported.

Reference:  
https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html

---

## 2️⃣ Downgrade Is Not Supported

You **cannot downgrade** a cluster after upgrading.

Rollback strategy = **halt progression and stabilize**, not revert version.

Reference:  
https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html

---

## 3️⃣ Add-ons Are NOT Automatically Upgraded

Control plane upgrades do **not** automatically upgrade:

- VPC CNI
- kube-proxy
- CoreDNS
- CSI drivers
- Other managed add-ons

These must be upgraded explicitly.

Reference:  
https://docs.aws.amazon.com/eks/latest/userguide/updating-an-add-on.html

---

## 4️⃣ Managed Node Group Updates Respect PDBs

Managed node groups use rolling updates and respect **PodDisruptionBudgets (PDBs)**.

Do not force updates unless fully understanding the disruption impact.

Reference:  
https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html

---

# 🛑 Mandatory Pre-Upgrade Gates

All gates must pass before proceeding.

---

## Gate A — Cluster Health

Cluster must be fully stable.

Abort if:

- Any node is `NotReady`
- CrashLoopBackOff pods exist in system namespaces
- Degraded DaemonSets
- DNS instability
- Ongoing incident

### Checks

```bash
kubectl get nodes -o wide
kubectl -n kube-system get pods -o wide
kubectl get pods -A --field-selector=status.phase!=Running
kubectl get pdb -A
```

---

## Gate B — EKS Upgrade Insights

Use EKS Upgrade Insights to detect:

- Deprecated API usage
- Known upgrade blockers

Console path:

```
EKS → Cluster → Observability → Upgrade Insights
```

Resolve all findings before proceeding.

Reference:  
https://docs.aws.amazon.com/eks/latest/userguide/cluster-insights.html

---

## Gate C — Confirm Supported Versions in Your Region

Never assume the latest version.

```bash
aws eks describe-cluster-versions --region <REGION>
```

Reference:  
https://docs.aws.amazon.com/cli/latest/reference/eks/describe-cluster-versions.html

---

## Gate D — Confirm Current Cluster Version

```bash
aws eks describe-cluster \
  --name <CLUSTER_NAME> \
  --region <REGION> \
  --query "cluster.version" \
  --output text
```

Reference:  
https://docs.aws.amazon.com/cli/latest/reference/eks/describe-cluster.html

---

## Gate E — Data Protection Decision (Stateful Workloads)

EKS manages the control plane datastore.  
You are responsible for application data.

If running:

- StatefulSets
- EBS-backed PVCs
- In-cluster databases

You must define and execute snapshot policy aligned with RPO/RTO.

---

# 🔁 Canonical Upgrade Order (Per Minor Version)

For each version increment:

1. Pre-check gates
2. Upgrade Control Plane
3. Upgrade Add-ons
4. Upgrade Managed Node Groups
5. Validate + Stabilize

Repeat for next minor.

Reference:  
https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html

---

# ⚙️ Step-by-Step Execution (AWS CLI)

## Set Variables

```bash
export CLUSTER_NAME="<CLUSTER_NAME>"
export REGION="<REGION>"
```

---

## Step 1 — Identify Next Minor Version

```bash
aws eks describe-cluster-versions --region "$REGION"

aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --query "cluster.version" \
  --output text
```

Select the next minor only.

---

## Step 2 — Upgrade Control Plane

```bash
aws eks update-cluster-version \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --kubernetes-version "<TARGET_VERSION>"
```

Monitor:

```bash
aws eks list-updates \
  --name "$CLUSTER_NAME" \
  --region "$REGION"

aws eks describe-update \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --update-id "<UPDATE_ID>"
```

Wait until cluster status is `ACTIVE`.

---

## Step 3 — Upgrade Managed Add-ons

List add-ons:

```bash
aws eks list-addons \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION"
```

Check compatible versions:

```bash
aws eks describe-addon-versions \
  --addon-name <ADDON_NAME> \
  --kubernetes-version "<TARGET_VERSION>" \
  --region "$REGION"
```

Update add-on:

```bash
aws eks update-addon \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name <ADDON_NAME> \
  --addon-version "<ADDON_VERSION>" \
  --region "$REGION"
```

Recommended upgrade order:

1. vpc-cni
2. kube-proxy
3. coredns
4. aws-ebs-csi-driver

---

## Step 4 — Upgrade Managed Node Groups

List node groups:

```bash
aws eks list-nodegroups \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION"
```

Update node group:

```bash
aws eks update-nodegroup-version \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "<NODEGROUP_NAME>" \
  --region "$REGION"
```

Monitor update progress until complete.

---

# ✅ Post-Upgrade Validation

```bash
kubectl get nodes -o wide
kubectl -n kube-system get pods
kubectl get events -A --sort-by=.lastTimestamp | tail -n 50
```

Verify:

- All nodes on target version
- CoreDNS healthy
- Networking stable
- No unexpected pod failures
- Monitoring stable

Allow a stabilization soak window before next hop.

---

# ⚠️ Common Failure Scenarios

## 1️⃣ Deprecated API Usage

**Symptom:** Upgrade blocked or workloads fail after upgrade.  
**Cause:** Workloads using removed API versions.  
**Mitigation:** Use Upgrade Insights and update manifests before upgrade.

---

## 2️⃣ Add-on Version Mismatch

**Symptom:** DNS failures or pod networking issues.  
**Cause:** CNI or CoreDNS not aligned with cluster version.  
**Mitigation:** Explicitly upgrade add-ons immediately after control plane upgrade.

---

## 3️⃣ Node Group Update Blocked by PDB

**Symptom:** Node update stalls.  
**Cause:** PodDisruptionBudget prevents pod eviction.

**Mitigation:**

- Increase replicas
- Adjust PDB temporarily
- Add temporary capacity

---

## 4️⃣ Capacity Shortage During Rolling Update

**Symptom:** Pending pods during node replacement.  
**Cause:** No spare capacity during rotation.

**Mitigation:**

- Increase node group desired capacity temporarily
- Ensure autoscaler headroom

---

## 5️⃣ Stateful Workload Volume Attach Delays

**Symptom:** Pods stuck in `ContainerCreating`.  
**Cause:** EBS detach/attach latency during node rotation.

**Mitigation:**

- Ensure multi-AZ design
- Validate volume limits per node
- Monitor attach events

---

## 6️⃣ Monitoring Blind During Upgrade

**Symptom:** Cannot assess cluster health.  
**Cause:** Observability stack dependent on nodes being rotated.

**Mitigation:**

- Validate monitoring stability before upgrade
- Ensure redundancy in monitoring components

---

# 📚 Official Best Practice Reference

Cluster Upgrade Best Practices:  
https://docs.aws.amazon.com/eks/latest/best-practices/cluster-upgrades.html