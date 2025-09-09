# ------------------------------------------------------------
# Outputs for GitHub Actions Secrets
# ------------------------------------------------------------

output "ROTATE_LAMBDA_ROLE_ARN" {
  description = "ARN of the IAM role for the rotate Lambda"
  value       = aws_iam_role.rotate_lambda_exec.arn
}

output "PURGE_LAMBDA_ROLE_ARN" {
  description = "ARN of the IAM role for the purge Lambda"
  value       = aws_iam_role.purge_lambda_exec.arn
}

output "TARGET_USERNAME" {
  description = "IAM user whose keys are rotated"
  value       = var.target_username
}

output "SECRET_NAME" {
  description = "Secrets Manager secret name where the new keys go"
  value       = aws_secretsmanager_secret.iam_keys.name
}

output "SNS_TOPIC_ARN" {
  description = "ARN of the SNS topic for notifications"
  value       = aws_sns_topic.key_rotation.arn
}

output "SECRET_JSON_KEY" {
  description = "JSON key name inside the secret (default: current)"
  value       = coalesce(var.secret_json_key, "current")
}
