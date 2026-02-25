# ⚠️ Operational and Safety Guidelines

This repository provisions real cloud infrastructure and performs operations that may modify or destroy cloud resources.  
Review and understand the following operational guidelines before executing any commands or automation workflows.

---

## 1. Use of Example Values

All IP addresses, hostnames, account identifiers, resource names, ARNs, endpoints, and configuration values shown throughout this documentation are **illustrative examples only**.

Always rely on values returned by your own:

- CLI commands
- automation outputs
- Infrastructure as Code executions
- cloud provider APIs

**Never copy example values directly into a live environment.**

Using static example identifiers may result in deployment failures, unintended resource modification, or security exposure.

---

## 2. Infrastructure Cost Awareness

Cloud resources incur costs while provisioned — even when idle or not actively used.

Executing the examples contained in this repository may create billable resources including compute, networking, storage, and load balancing components.

You are responsible for monitoring usage and ensuring that infrastructure is removed when no longer required.

---

## 3. Infrastructure Lifecycle Management

All resources created during this walkthrough must be managed and destroyed using the appropriate lifecycle mechanism.

### 3.1 Manual Provisioning

If resources were created manually, terminate or delete them using your cloud provider’s:

- Management Console
- CLI tools
- API interfaces

---

### 3.2 Infrastructure as Code (IaC)

Resources provisioned using Infrastructure as Code **must be destroyed using the same tooling that created them**.

Example:

```bash
terraform destroy