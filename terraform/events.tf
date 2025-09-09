# ------------------------------------------------------------
# Optional EventBridge schedules to invoke Lambdas
# Controlled via var.enable_eventbridge_targets
# ------------------------------------------------------------

variable "enable_eventbridge_targets" {
  description = "Attach EventBridge rules/targets to schedule the Lambdas"
  type        = bool
  default     = false
}

variable "rotation_schedule_expression" {
  description = "Schedule for rotate lambda (EventBridge cron or rate)"
  type        = string
  default     = "cron(0 3 ? * MON *)" # every Monday 03:00 UTC
}

variable "purge_schedule_expression" {
  description = "Schedule for purge lambda (EventBridge cron or rate)"
  type        = string
  default     = "cron(30 3 * * ? *)" # daily 03:30 UTC
}

# These Lambda ARNs typically come from separate aws_lambda_function resources.
# If you deploy functions outside Terraform, you can pass ARNs in via variables instead.

# Rotation rule & target
resource "aws_cloudwatch_event_rule" "rotate_schedule" {
  count               = var.enable_eventbridge_targets ? 1 : 0
  name                = "rotate-keys-schedule"
  schedule_expression = var.rotation_schedule_expression
}

resource "aws_cloudwatch_event_target" "rotate_target" {
  count     = var.enable_eventbridge_targets ? 1 : 0
  rule      = aws_cloudwatch_event_rule.rotate_schedule[0].name
  target_id = "rotate-lambda"
  arn       = aws_lambda_function.rotate.arn
}

resource "aws_lambda_permission" "rotate_events" {
  count         = var.enable_eventbridge_targets ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgeRotate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotate_schedule[0].arn
}

# Purge rule & target
resource "aws_cloudwatch_event_rule" "purge_schedule" {
  count               = var.enable_eventbridge_targets ? 1 : 0
  name                = "purge-keys-schedule"
  schedule_expression = var.purge_schedule_expression
}

resource "aws_cloudwatch_event_target" "purge_target" {
  count     = var.enable_eventbridge_targets ? 1 : 0
  rule      = aws_cloudwatch_event_rule.purge_schedule[0].name
  target_id = "purge-lambda"
  arn       = aws_lambda_function.purge.arn
}

resource "aws_lambda_permission" "purge_events" {
  count         = var.enable_eventbridge_targets ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgePurge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.purge.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.purge_schedule[0].arn
}
