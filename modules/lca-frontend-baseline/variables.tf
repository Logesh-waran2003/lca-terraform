variable "lob" {
  description = "Line of Business name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "webapp_bucket_name" {
  description = "Name of the webapp S3 bucket"
  type        = string
}

variable "webapp_bucket_arn" {
  description = "ARN of the webapp S3 bucket"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
}
