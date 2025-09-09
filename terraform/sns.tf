resource "aws_sns_topic" "notify" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_policy" "topic_policy" {
  arn = aws_sns_topic.notify.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "DefaultAllowPublishFromAccount",
      Effect    = "Allow",
      Principal = { AWS = "*" },
      Action    = ["SNS:Publish"],
      Resource  = aws_sns_topic.notify.arn,
      Condition = { StringEquals = { "AWS:SourceOwner" = data.aws_caller_identity.current.account_id } }
    }]
  })
}

resource "aws_sns_topic_subscription" "email_subs" {
  for_each  = toset(var.sns_email_subscribers)
  topic_arn = aws_sns_topic.notify.arn
  protocol  = "email"
  endpoint  = each.value
}
