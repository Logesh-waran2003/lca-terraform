output "sns_topic_arn" {
  value = aws_sns_topic.category.arn
}

output "sns_topic_name" {
  value = aws_sns_topic.category.name
}

output "kms_key_arn" {
  value = aws_kms_key.sqs_managed.arn
}
