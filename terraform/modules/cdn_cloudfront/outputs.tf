output "ssl_cert_arn" {
  description = "The ARN of the SSL Certificate"
  value = aws_acm_certificate.ssl_certificate.arn
}

output "root_domain" {
  description = "The root domain name for the website"
  value       = var.root_domain
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website_distribution.id
}