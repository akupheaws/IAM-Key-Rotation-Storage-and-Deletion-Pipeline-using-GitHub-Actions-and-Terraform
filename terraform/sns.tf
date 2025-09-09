resource "aws_sns_topic" "key_rotation" {
  name = "iam-key-rotation-topic"
}

# Your email (default as requested)
variable "notification_email" {
  description = "Email address to subscribe to key rotation notifications"
  type        = string
  default     = "akupheaws@gmail.com"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.key_rotation.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
