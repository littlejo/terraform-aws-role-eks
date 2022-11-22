locals {
  eks_oidc_issuer_url   = var.oidc_provider != null ? var.oidc_provider : replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  eks_oidc_provider_arn = "arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"
}

data "aws_partition" "this" {}
data "aws_caller_identity" "this" {}

data "aws_eks_cluster" "this" {
  name = var.cluster_id
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    principals {
      type        = "Federated"
      identifiers = [local.eks_oidc_provider_arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringLike"
      variable = "${local.eks_oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:${var.service_account.namespace}:${var.service_account.name}"]
    }
    condition {
      test     = "StringLike"
      variable = "${local.eks_oidc_issuer_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = "AWS IAM Role for the Kubernetes service account ${var.service_account.name}."
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy.json
  path                 = var.role_path
  permissions_boundary = var.permissions_boundary

  inline_policy {
    name   = var.inline_policy_name
    policy = var.inline_policy
  }
}

resource "kubernetes_service_account_v1" "this" {
  count = var.create_sa ? 1 : 0
  metadata {
    name        = var.service_account.name
    namespace   = var.service_account.namespace
    annotations = { "eks.amazonaws.com/role-arn" : aws_iam_role.this.arn }
  }
  automount_service_account_token = var.service_account.automount
}
