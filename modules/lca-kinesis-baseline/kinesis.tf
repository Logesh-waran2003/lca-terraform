resource "aws_kinesis_stream" "call_data" {
  name = "call-data-stream-${var.lob}"

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_kinesis_stream_consumer" "data_stream" {
  name       = "data-stream-consumer-${var.lob}"
  stream_arn = aws_kinesis_stream.call_data.arn
}
