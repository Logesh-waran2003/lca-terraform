data "aws_s3_bucket" "webapp" {
  bucket = var.webapp_bucket_name
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "OAI for ${var.webapp_bucket_name}"
}

resource "aws_s3_bucket_policy" "webapp" {
  bucket = var.webapp_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAI"
        Effect    = "Allow"
        Principal = { CanonicalUser = aws_cloudfront_origin_access_identity.main.s3_canonical_user_id }
        Action    = "s3:GetObject"
        Resource  = "${var.webapp_bucket_arn}/*"
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:*"]
        Resource = [
          var.webapp_bucket_arn,
          "${var.webapp_bucket_arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "webapp" {
  enabled             = true
  default_root_object = "index.html"
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  comment             = "LCA web app - ${var.lob}"

  origin {
    domain_name = data.aws_s3_bucket.webapp.bucket_regional_domain_name
    origin_id   = "webapp-s3-bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "webapp-s3-bucket"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    default_ttl            = 600
    min_ttl                = 300
    max_ttl                = 900

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}
