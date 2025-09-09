variable "aws_region"               { type = string, default = "us-east-1" }
variable "target_username"          { type = string }
variable "secret_name"              { type = string }
variable "secret_json_key"          { type = string, default = "current" }
variable "sns_topic_name"           { type = string, default = "iam-key-rotation-notify" }
variable "sns_email_subscribers"    { type = list(string), default = [] }
variable "rotate_lambda_role_name"  { type = string, default = "RotateAndDeactivateKeysRole" }
variable "purge_lambda_role_name"   { type = string, default = "PurgeDeactivatedKeysRole" }
variable "rotate_lambda_function_name" { type = string, default = "rotate-and-deactivate-keys" }
variable "purge_lambda_function_name"  { type = string, default = "purge-deactivated-keys" }
variable "enable_eventbridge_targets"  { type = bool,   default = false }
variable "rotation_schedule_expression"{ type = string, default = "cron(0 3 ? * MON *)" }
variable "purge_schedule_expression"   { type = string, default = "cron(30 3 * * ? *)" }
