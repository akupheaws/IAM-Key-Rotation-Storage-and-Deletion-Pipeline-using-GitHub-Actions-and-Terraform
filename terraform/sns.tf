# ------------------------------------------------------------
# SNS topic for IAM key rotation notifications
# ------------------------------------------------------------

resource "aws_sns_topic" "key_rotation" {
  name = "iam-key-rotation-topic"
}

# Optional email subscription (set email in tfvars or skip)
variable "notification_email" {
  description = "Email address to subscribe to key rotation notifications (optional)"
  type        = string
  default     = ""
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.key_rotation.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
