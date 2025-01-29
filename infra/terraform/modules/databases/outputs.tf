output "mongodb_public_ip" {
  value = aws_instance.mongodb.public_ip
}

output "redis_public_ip" {
  value = aws_instance.redis.public_ip
}

output "mysql_public_ip" {
  value = aws_instance.mysql.public_ip
}