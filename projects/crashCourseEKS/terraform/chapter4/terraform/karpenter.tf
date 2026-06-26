# karpenter.tf

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.3.3"

  wait = true

  values = [
    yamlencode({
      serviceAccount = {
        name = "karpenter"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.karpenter_irsa.iam_role_arn
        }
      }

      settings = {
        clusterName = var.cluster_name
      }
    })
  ]

  depends_on = [
    module.eks,
    module.karpenter_irsa
  ]
}