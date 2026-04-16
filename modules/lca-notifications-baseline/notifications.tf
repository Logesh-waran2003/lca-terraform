resource "aws_kms_key" "sqs_managed" {
  description         = "KMS key for LCA SNS - ${var.lob}"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRootAccount"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowS3Service"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_kms_alias" "sqs_managed" {
  name          = "alias/lca-kms-${var.lob}"
  target_key_id = aws_kms_key.sqs_managed.key_id
}

resource "aws_sns_topic" "category" {
  name              = "category-sns-${var.lob}"
  kms_master_key_id = aws_kms_key.sqs_managed.arn

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}
