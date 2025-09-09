output "rotate_lambda_role_arn" {
  description = "GitHub secret ROTATE_LAMBDA_ROLE_ARN"
  value       = aws_iam_role.rotate_role.arn
}
output "purge_lambda_role_arn" {
  description = "GitHub secret PURGE_LAMBDA_ROLE_ARN"
  value       = aws_iam_role.purge_role.arn
}
output "sns_topic_arn" {
  description = "GitHub secret SNS_TOPIC_ARN"
  value       = aws_sns_topic.notify.arn
}
output "secret_name" {
  description = "Use as SECRET_NAME"
  value       = aws_secretsmanager_secret.key_secret.name
}
