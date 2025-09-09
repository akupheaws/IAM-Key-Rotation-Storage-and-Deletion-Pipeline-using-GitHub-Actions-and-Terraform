aws_region      = "us-east-1"
target_username = "my-service-user"
secret_name     = "iam/service-user/keys"
secret_json_key = "current"

# EventBridge (optional)
enable_eventbridge_targets   = false
rotation_schedule_expression = "cron(0 3 ? * MON *)"
purge_schedule_expression    = "cron(30 3 * * ? *)"

# If you enable EventBridge targets, provide these:
# rotate_lambda_arn  = "arn:aws:lambda:us-east-1:123456789012:function:rotate-and-deactivate-keys"
# rotate_lambda_name = "rotate-and-deactivate-keys"
# purge_lambda_arn   = "arn:aws:lambda:us-east-1:123456789012:function:purge-deactivated-keys"
# purge_lambda_name  = "purge-deactivated-keys"
