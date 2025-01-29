output "private_app_private_ip" {
  description = "Private IP of the instance in the second VPC"
  value       = aws_instance.private_app.private_ip
}