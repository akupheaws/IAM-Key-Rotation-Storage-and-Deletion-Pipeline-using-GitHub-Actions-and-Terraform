# ------------------------------------------------------------
# Outputs for GitHub Actions Secrets
# These values should be copied into your GitHub repository
# Settings → Secrets and variables → Actions
# ------------------------------------------------------------

output "ROTATE_LAMBDA_ROLE_ARN" {
  description = "ARN of the IAM role attached to the rotate-and-deactivate-keys Lambda function"
  value       = aws_iam_role.rotate_lambda_exec.arn
}

output "PURGE_LAMBDA_ROLE_ARN" {
  description = "ARN of the IAM role attached to the purge-deactivated-keys Lambda function"
  value       = aws_iam_role.purge_lambda_exec.arn
}

output "TARGET_USERNAME" {
  description = "The IAM user whose access keys will be rotated"
  value       = var.target_username
}

output "SECRET_NAME" {
  description = "The AWS Secrets Manager secret name where new IAM keys will be stored"
  value       = var.secret_name
}

output "SNS_TOPIC_ARN" {
  description = "ARN of the SNS topic that receives key rotation notifications"
  value       = aws_sns_topic.key_rotation.arn
}

output "SECRET_JSON_KEY" {
  description = "The JSON key name inside the secret where IAM keys are stored (default: current)"
  value       = coalesce(var.secret_json_key, "current")
}
