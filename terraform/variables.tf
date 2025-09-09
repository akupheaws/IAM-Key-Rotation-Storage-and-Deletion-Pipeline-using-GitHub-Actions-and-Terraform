# ------------------------------------------------------------
# Core configuration variables
# ------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "target_username" {
  description = "The IAM user whose access keys will be rotated"
  type        = string
}

variable "secret_name" {
  description = "Name of the AWS Secrets Manager secret where IAM keys are stored"
  type        = string
}

variable "secret_json_key" {
  description = "JSON key name inside the secret (default: current)"
  type        = string
  default     = "current"
}

# ------------------------------------------------------------
# Lambda IAM Role names
# ------------------------------------------------------------

variable "rotate_lambda_role_name" {
  description = "IAM role name for the rotate-and-deactivate-keys Lambda"
  type        = string
  default     = "rotate-lambda-exec"
}

variable "purge_lambda_role_name" {
  description = "IAM role name for the purge-deactivated-keys Lambda"
  type        = string
  default     = "purge-lambda-exec"
}
