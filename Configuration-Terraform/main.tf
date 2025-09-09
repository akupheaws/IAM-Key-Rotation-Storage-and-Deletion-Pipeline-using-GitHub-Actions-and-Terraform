resource "aws_vpc" "app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.common_tags, { Name = var.vpc_name })
}

resource "aws_subnet" "app_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, { Name = var.subnet_name })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags   = merge(var.common_tags, { Name = "${var.vpc_name}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app_vpc.id
  tags   = merge(var.common_tags, { Name = "${var.vpc_name}-public-rt" })
}

resource "aws_route" "public_to_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.app_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_sg" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "tcp"
    cidr_blocks = var.http_cidr_blocks
  }

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = var.sg_name })
}

resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.app_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name
  associate_public_ip_address = true
  depends_on = [aws_route_table_association.public_assoc]

  user_data = <<-EOT
#!/bin/bash
set -euxo pipefail
if command -v dnf >/dev/null 2>&1; then
  dnf -y update
  dnf -y install nginx
elif command -v yum >/dev/null 2>&1; then
  yum -y update
  if command -v amazon-linux-extras >/dev/null 2>&1; then
    amazon-linux-extras enable nginx1 || true
  fi
  yum -y install nginx
else
  apt-get update -y || true
  apt-get install -y nginx || true
fi
cat >/usr/share/nginx/html/index.html <<HTML
<!doctype html>
<html lang="en"><meta charset="utf-8">
<title>NGINX is running</title>
<style>body{font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;margin:2rem;line-height:1.5}</style>
<h1>NGINX is running</h1>
<p>Server: <code>$(hostname)</code></p>
<p>Time: <code>$(date)</code></p>
</html>
HTML
systemctl enable nginx
systemctl restart nginx
EOT

  tags = merge(var.common_tags, { Name = var.instance_name })
}
