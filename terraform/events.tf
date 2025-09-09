# ------------------------------------------------------------
# EventBridge schedules to invoke Lambdas (optional)
# Use enable_eventbridge_targets to turn on/off
# Pass Lambda ARNs/names via variables since code is deployed via GitHub Actions
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

# Provide these from outside (e.g., via tfvars or as outputs you paste from AWS)
variable "rotate_lambda_arn" {
  description = "ARN of the rotate-and-deactivate-keys Lambda"
  type        = string
  default     = ""
}

variable "rotate_lambda_name" {
  description = "Function name of the rotate Lambda (e.g., rotate-and-deactivate-keys)"
  type        = string
  default     = "rotate-and-deactivate-keys"
}

variable "purge_lambda_arn" {
  description = "ARN of the purge-deactivated-keys Lambda"
  type        = string
  default     = ""
}

variable "purge_lambda_name" {
  description = "Function name of the purge Lambda (e.g., purge-deactivated-keys)"
  type        = string
  default     = "purge-deactivated-keys"
}

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
  arn       = var.rotate_lambda_arn
}

resource "aws_lambda_permission" "rotate_events" {
  count         = var.enable_eventbridge_targets ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgeRotate"
  action        = "lambda:InvokeFunction"
  function_name = var.rotate_lambda_name
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
  arn       = var.purge_lambda_arn
}

resource "aws_lambda_permission" "purge_events" {
  count         = var.enable_eventbridge_targets ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgePurge"
  action        = "lambda:InvokeFunction"
  function_name = var.purge_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.purge_schedule[0].arn
}
