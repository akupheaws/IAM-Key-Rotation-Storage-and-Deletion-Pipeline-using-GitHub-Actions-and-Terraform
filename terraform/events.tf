resource "aws_cloudwatch_event_rule" "rotation_rule" {
  name                = "iam-key-rotation-schedule"
  description         = "Rotate & deactivate for ${var.target_username}"
  schedule_expression = var.rotation_schedule_expression
}

resource "aws_cloudwatch_event_rule" "purge_rule" {
  name                = "iam-key-purge-schedule"
  description         = "Delete inactive keys for ${var.target_username}"
  schedule_expression = var.purge_schedule_expression
}

data "aws_lambda_function" "rotate_fn" {
  count         = var.enable_eventbridge_targets ? 1 : 0
  function_name = var.rotate_lambda_function_name
}

data "aws_lambda_function" "purge_fn" {
  count         = var.enable_eventbridge_targets ? 1 : 0
  function_name = var.purge_lambda_function_name
}

resource "aws_cloudwatch_event_target" "rotation_target" {
  count     = var.enable_eventbridge_targets ? 1 : 0
  rule      = aws_cloudwatch_event_rule.rotation_rule.name
  target_id = "rotate-and-deactivate"
  arn       = data.aws_lambda_function.rotate_fn[0].arn
}

resource "aws_cloudwatch_event_target" "purge_target" {
  count     = var.enable_eventbridge_targets ? 1 : 0
  rule      = aws_cloudwatch_event_rule.purge_rule.name
  target_id = "purge-deactivated"
  arn       = data.aws_lambda_function.purge_fn[0].arn
}

resource "aws_lambda_permission" "rotation_invoke" {
  count        = var.enable_eventbridge_targets ? 1 : 0
  statement_id = "AllowEventBridgeInvokeRotate"
  action       = "lambda:InvokeFunction"
  function_name= data.aws_lambda_function.rotate_fn[0].function_name
  principal    = "events.amazonaws.com"
  source_arn   = aws_cloudwatch_event_rule.rotation_rule.arn
}

resource "aws_lambda_permission" "purge_invoke" {
  count        = var.enable_eventbridge_targets ? 1 : 0
  statement_id = "AllowEventBridgeInvokePurge"
  action       = "lambda:InvokeFunction"
  function_name= data.aws_lambda_function.purge_fn[0].function_name
  principal    = "events.amazonaws.com"
  source_arn   = aws_cloudwatch_event_rule.purge_rule.arn
}
