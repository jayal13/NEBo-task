output "key_pair" {
  value = aws_key_pair.nebo.key_name
}

output "public_ip" {
  value = aws_instance.app.public_ip
}

output "sg_id" {
  value = aws_security_group.sg.id
}