# addons.tf

resource "aws_eks_addon" "addons" {

  for_each = {

    coredns = {
      version = "v1.11.4-eksbuild.24"
    }

    kube-proxy = {
      version = "v1.29.15-eksbuild.16"
    }

    vpc-cni = {
      version = "v1.20.4-eksbuild.2"
    }

    aws-ebs-csi-driver = {
      version = "v1.38.1-eksbuild.2"
    }

    eks-pod-identity-agent = {
      version = "v1.3.5-eksbuild.2"
    }
  }

  cluster_name  = module.eks.cluster_name
  addon_name    = each.key
  addon_version = each.value.version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Temporary simplified approach for learning/lab environments.
  # Production environments should use dedicated IRSA roles.
  service_account_role_arn = (
    each.key == "aws-ebs-csi-driver"
    ? module.eks.eks_managed_node_groups["default"].iam_role_arn
    : null
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    module.eks
  ]
}