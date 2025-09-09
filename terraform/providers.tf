terraform {
  required_version = ">= 1.6.0"

  backend "s3" {}  # values come from -backend-config in your workflow

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

# Keep this here (single definition for the whole module)
data "aws_caller_identity" "current" {}
