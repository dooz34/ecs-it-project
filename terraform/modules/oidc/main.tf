variable "github_repo" {
  description = "GitHub repo in the form org/repo, e.g. dooz34/ECS-IT-PROJECT"
  type        = string
}
variable "role_name" {
  description = "Name for the IAM role GitHub Actions will assume"
  type        = string
  default     = "github-actions-oidc-role"
}
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:dooz34@153876543/ecs-it-project@1329066164:*"
      ]
    }
  }
}
resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json

  lifecycle {
    prevent_destroy = true
  }
}
data "aws_iam_policy_document" "permissions" {
  statement {
    sid = "ECRPush"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:CreateRepository",
      "ecr:DescribeRepositories",
    ]
    resources = ["*"]
  }
  statement {
    sid = "ECSDeploy"
    actions = [
      "ecs:*",
      "elasticloadbalancing:*",
      "ec2:*",
      "acm:*",
      "route53:*",
      "logs:*",
      "ssm:GetParameter*",
      "ssm:PutParameter",
      "secretsmanager:*",
    ]
    resources = ["*"]
  }
  statement {
    sid = "IAMPassRoleForECS"
    actions = [
      "iam:PassRole", "iam:CreateRole", "iam:DeleteRole",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRole",
      "iam:GetRolePolicy", "iam:UpdateAssumeRolePolicy",
      "iam:TagRole", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:CreatePolicy", "iam:DeletePolicy", "iam:GetPolicy",
      "iam:GetPolicyVersion", "iam:ListPolicyVersions",
      "iam:GetOpenIDConnectProvider", "iam:ListOpenIDConnectProviders",
      "iam:CreateOpenIDConnectProvider", "iam:DeleteOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint", "iam:TagOpenIDConnectProvider"
    ]
    resources = ["*"]
  }
  statement {
    sid = "TerraformState"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject",
      "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.role_name}-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.permissions.json

  lifecycle {
    prevent_destroy = true
  }
}
output "role_arn" {
  value = aws_iam_role.github_actions.arn
}