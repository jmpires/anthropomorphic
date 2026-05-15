# main.tf

data "aws_caller_identity" "current" {}

locals {
  runner_arn = data.aws_caller_identity.current.arn
}