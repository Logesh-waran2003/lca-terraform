output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.webapp.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.webapp.id
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.webapp.domain_name}"
}
