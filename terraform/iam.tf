locals {
  user_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.target_username}"
}

# ------------------------------------------------------------
# Lambda Assume Role Policy
# ------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ------------------------------------------------------------
# Rotate Lambda Role + Policy
# ------------------------------------------------------------
resource "aws_iam_role" "rotate_lambda_exec" {
  name               = var.rotate_lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "rotate_inline" {
  statement {
    sid     = "IAMListCreateUpdate"
    effect  = "Allow"
    actions = [
      "iam:ListAccessKeys",
      "iam:CreateAccessKey",
      "iam:UpdateAccessKey",
    ]
  # limit to the target user only
    resources = [local.user_arn]
  }

  statement {
    sid     = "SecretsWrite"
    effect  = "Allow"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}*",
    ]
  }

  statement {
    sid     = "SNSPublish"
    effect  = "Allow"
    actions = ["sns:Publish"]
    resources = [aws_sns_topic.key_rotation.arn]
  }

  statement {
    sid     = "Logs"
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "rotate_policy" {
  name   = "${var.rotate_lambda_role_name}-inline"
  policy = data.aws_iam_policy_document.rotate_inline.json
}

resource "aws_iam_role_policy_attachment" "rotate_attach" {
  role       = aws_iam_role.rotate_lambda_exec.name
  policy_arn = aws_iam_policy.rotate_policy.arn
}

# ------------------------------------------------------------
# Purge Lambda Role + Policy
# ------------------------------------------------------------
resource "aws_iam_role" "purge_lambda_exec" {
  name               = var.purge_lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "purge_inline" {
  statement {
    sid     = "IAMListDelete"
    effect  = "Allow"
    actions = [
      "iam:ListAccessKeys",
      "iam:DeleteAccessKey",
    ]
  # limit to the target user only
    resources = [local.user_arn]
  }

  statement {
    sid     = "Logs"
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "purge_policy" {
  name   = "${var.purge_lambda_role_name}-inline"
  policy = data.aws_iam_policy_document.purge_inline.json
}

resource "aws_iam_role_policy_attachment" "purge_attach" {
  role       = aws_iam_role.purge_lambda_exec.name
  policy_arn = aws_iam_policy.purge_policy.arn
}
