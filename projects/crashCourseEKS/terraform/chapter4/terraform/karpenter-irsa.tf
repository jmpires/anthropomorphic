# karpenter-irsa.tf

module "karpenter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${var.cluster_name}-karpenter-irsa"

  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name = var.cluster_name

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }

  tags = {
    environment = var.tag_environment
    application = var.tag_application
  }
}

resource "aws_iam_role_policy" "karpenter_instance_profile" {
  name = "${var.cluster_name}-karpenter-instance-profile"
  role = module.karpenter_irsa.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ManageInstanceProfiles"
        Effect = "Allow"

        Action = [
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "karpenter_runinstances_override" {
  name = "${var.cluster_name}-karpenter-runinstances-override"
  role = module.karpenter_irsa.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowRunInstances"
        Effect = "Allow"

        Action = [
          "ec2:RunInstances"
        ]

        Resource = "*"
      }
    ]
  })
}