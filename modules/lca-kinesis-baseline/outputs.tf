output "stream_name" {
  value = aws_kinesis_stream.call_data.name
}

output "stream_arn" {
  value = aws_kinesis_stream.call_data.arn
}

output "consumer_arn" {
  value = aws_kinesis_stream_consumer.data_stream.arn
}
