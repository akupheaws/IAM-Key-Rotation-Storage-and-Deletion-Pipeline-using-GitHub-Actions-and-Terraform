output "web_instance_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Public IP of the web server"
}

output "web_instance_public_dns" {
  value       = aws_instance.web_server.public_dns
  description = "Public DNS of the web server"
}

output "security_group_id" {
  value       = aws_security_group.web_sg.id
  description = "ID of the web security group"
}

output "vpc_id" {
  value       = aws_vpc.app_vpc.id
  description = "ID of the VPC"
}

output "web_url" {
  value       = "http://${aws_instance.web_server.public_ip}"
  description = "Open this URL to confirm the NGINX welcome page."
}
