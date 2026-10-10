# GitHub Actions gets short-lived AWS credentials through OIDC: no access keys stored in GitHub.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_trust" {
  statement {
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
    # Only workflows running on main of this repo; PRs and other branches can't assume it
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
    # Same repo by numeric ID, which survives renames and can't be reclaimed by a new repo
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository_id"
      values   = [var.github_repo_id]
    }
    # ...and only the shared pipeline at a release tag, not an edited copy of it in this repo.
    # Both spellings of the same workflow: by name, and by name@id (GitHub's immutable form).
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = [for w in var.shared_workflow_refs : "${w}@refs/tags/v*"]
    }
  }
}

resource "aws_iam_role" "github_ci" {
  name               = "${var.name}-github-ci"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # this action does not support resource-level permissions
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [aws_ecr_repository.calculator.arn]
  }
}

resource "aws_iam_role_policy" "github_ci_ecr_push" {
  name   = "ecr-push"
  role   = aws_iam_role.github_ci.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
