data "aws_iam_policy_document" "ecr_push" {
  # Registry login; this action doesn't support resource-level permissions.
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PushToAppRepositories"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
    ]
    resources = var.ecr_repository_arns
  }
}

data "aws_iam_policy_document" "ecr_scan" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PullFromAppRepositories"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = var.ecr_repository_arns
  }
}

# Plans read state and take the lock: with S3 native locking the lock is a
# `<key>.tflock` object written next to the state, so plan needs Put/Delete on
# those objects only. Objects are encrypted with the state KMS key.
data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]
  }

  statement {
    sid       = "ReadState"
    actions   = ["s3:GetObject"]
    resources = ["${var.state_bucket_arn}/*"]
  }

  statement {
    sid       = "ManageLockFiles"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.state_bucket_arn}/*.tflock"]
  }

  statement {
    sid       = "UseStateKey"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = [var.state_kms_key_arn]
  }
}
