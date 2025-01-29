output "public_ip" {
  value = module.compute.public_ip
}

output "mongodb_public_ip" {
  value = module.databases.mongodb_public_ip
}

output "redis_public_ip" {
  value = module.databases.redis_public_ip
}

output "mysql_public_ip" {
  value = module.databases.mysql_public_ip
}

output "private_app_private_ip" {
  description = "Private IP of the instance in the second VPC"
  value       = module.private_network.private_app_private_ip
}

output "cloudfront_distribution_domain" {
  description = "URL del sitio web con CDN en CloudFront"
  value       = module.s3.cloudfront_distribution_domain
}