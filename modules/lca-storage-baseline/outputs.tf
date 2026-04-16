output "webapp_bucket_name" {
  value = aws_s3_bucket.webapp.id
}

output "webapp_bucket_arn" {
  value = aws_s3_bucket.webapp.arn
}

output "recordings_bucket_name" {
  value = aws_s3_bucket.recordings.id
}

output "recordings_bucket_arn" {
  value = aws_s3_bucket.recordings.arn
}
