# ------------------------------------------------------------
# EventBridge schedules for Rotate/Purge Lambdas
# Uses data sources to resolve ARNs by function name
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
  default     = "cron(30 3 * * ? *)"  # daily 03:30 UTC
}

variable "rotate_lambda_name" {
  description = "Function name of the rotate Lambda"
  type        = string
  default     = "rotate-and-deactivate-keys"
}

variable "purge_lambda_name" {
  description = "Function name of the purge Lambda"
  type        = string
  default     = "purge-deactivated-keys"
}

# Optional overrides (normally keep null to auto-resolve by name)
variable "rotate_lambda_arn" {
  description = "Optional ARN override for rotate Lambda"
  type        = string
  default     = null
}

variable "purge_lambda_arn" {
  description = "Optional ARN override for purge Lambda"
  type        = string
  default     = null
}

# Look up existing Lambdas by name (they are deployed by GitHub Actions)
data "aws_lambda_function" "rotate" {
  function_name = var.rotate_lambda_name
}

data "aws_lambda_function" "purge" {
  function_name = var.purge_lambda_name
}

locals {
  rotate_lambda_arn = coalesce(var.rotate_lambda_arn, data.aws_lambda_function.rotate.arn)
  purge_lambda_arn  = coalesce(var.purge_lambda_arn,  data.aws_lambda_function.purge.arn)
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
  arn       = local.rotate_lambda_arn
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
  arn       = local.purge_lambda_arn
}

resource "aws_lambda_permission" "purge_events" {
  count         = var.enable_eventbridge_targets ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgePurge"
  action        = "lambda:InvokeFunction"
  function_name = var.purge_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.purge_schedule[0].arn
}
