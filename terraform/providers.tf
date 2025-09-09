terraform {
  required_version = ">= 1.6.0"

  # Backend values are provided via -backend-config in the workflow
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Single definition for caller identity (do not duplicate in other files)
data "aws_caller_identity" "current" {}
