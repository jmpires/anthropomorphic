3) Update EKS-managed add-ons for Kubernetes 1.29 (do this before node roll)
Why: kube-proxy and CoreDNS run on nodes and are version-sensitive; VPC CNI is also tightly coupled to networking behavior. AWS documents managing these add-ons explicitly.
3.1 (Recommended) Find the "default" recommended versions for 1.29
This shows what EKS recommends for your target Kubernetes version:


aws eks describe-addon-versions \
  --region "$AWS_REGION" \
  --kubernetes-version "1.29" \
  --addon-names vpc-cni coredns kube-proxy aws-ebs-csi-driver \
  --query "addons[].{addon:addonName, versions:addonVersions[?compatibilities[?defaultVersion==`true`]].addonVersion}" \
  --output table


3.2 Update the core add-ons (pick what applies to your cluster)
For each add-on you actually have installed (from list-addons), run:

VPC CNI
aws eks update-addon \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name vpc-cni \
  --resolve-conflicts OVERWRITE

CoreDNS
aws eks update-addon \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name coredns \
  --resolve-conflicts OVERWRITE

kube-proxy
aws eks update-addon \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name kube-proxy \
  --resolve-conflicts OVERWRITE

(If you use it) EBS CSI driver
aws eks update-addon \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name aws-ebs-csi-driver \
  --resolve-conflicts OVERWRITE


3.3 Wait for each add-on to become ACTIVE

for ADDON in vpc-cni coredns kube-proxy aws-ebs-csi-driver; do
  aws eks wait addon-active --region "$AWS_REGION" --cluster-name "$CLUSTER_NAME" --addon-name "$ADDON" || true
done

(The addon-active waiter exists alongside other EKS waiters.)