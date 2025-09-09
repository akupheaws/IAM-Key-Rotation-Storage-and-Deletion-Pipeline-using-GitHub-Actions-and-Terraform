
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "sentara-app-vpc"
}

variable "subnet_name" {
  description = "Name tag for the subnet"
  type        = string
  default     = "sentara-app-subnet"
}

variable "sg_name" {
  description = "Name for the web server security group"
  type        = string
  default     = "web-server-sg"
}

variable "sg_description" {
  description = "Description for the web server security group"
  type        = string
  default     = "Allow HTTP and SSH inbound traffic"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "sentara-web-server"
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "sentara-app"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

variable "http_port" {
  description = "HTTP port to open"
  type        = number
  default     = 80
}

variable "ssh_port" {
  description = "SSH port to open"
  type        = number
  default     = 22
}

variable "http_cidr_blocks" {
  description = "CIDR blocks allowed to access HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH (restrict in prod!)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ami_id" {
  description = "AMI ID for the instance (region-specific)"
  type        = string
  default     = "ami-00ca32bbc84273381"
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH (optional)"
  type        = string
  default     = null
}
