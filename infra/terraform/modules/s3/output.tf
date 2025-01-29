output "cloudfront_distribution_domain" {
  description = "URL del sitio web con CDN en CloudFront"
  value       = aws_cloudfront_distribution.cdn.domain_name
}