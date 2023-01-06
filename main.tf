locals {
  eks_oidc_issuer_url   = var.oidc_provider != null ? var.oidc_provider : replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  eks_oidc_provider_arn = "arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"

  sa_arns          = [for k, sa in var.service_accounts : "system:serviceaccount:${sa.namespace}:${sa.name}"]
  sa_str           = join(", ", [for k, sa in var.service_accounts : "${sa.namespace}/${sa.name}"])
  service_accounts = var.create_sa ? var.service_accounts : {}
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
      values   = local.sa_arns
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
  description          = "AWS IAM Role for the Kubernetes service accounts: ${local.sa_str}."
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy.json
  path                 = var.role_path
  permissions_boundary = var.permissions_boundary

  dynamic "inline_policy" {
    for_each = var.inline_policies
    content {
      name   = inline_policy.key
      policy = inline_policy.value
    }
  }
}

resource "kubernetes_service_account_v1" "this" {
  for_each = local.service_accounts
  metadata {
    name        = each.value.name
    namespace   = each.value.namespace
    annotations = { "eks.amazonaws.com/role-arn" : aws_iam_role.this.arn }
  }
  automount_service_account_token = each.value.automount
}
