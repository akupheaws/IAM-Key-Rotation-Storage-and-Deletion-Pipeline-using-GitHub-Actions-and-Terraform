variable "aws_region"       { type = string,  default = "us-east-1" }
variable "state_bucket_name"{ type = string,  description = "teksystems-s3-infra-github-akuphe" }
variable "lock_table_name"  { type = string,  default = "terraform-state-locks" }
