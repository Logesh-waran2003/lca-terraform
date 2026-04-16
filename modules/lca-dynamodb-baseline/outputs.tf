output "event_sourcing_table_name" {
  value = aws_dynamodb_table.event_sourcing.name
}

output "event_sourcing_table_arn" {
  value = aws_dynamodb_table.event_sourcing.arn
}

output "llm_prompt_table_name" {
  value = aws_dynamodb_table.llm_prompt_template.name
}

output "llm_prompt_table_arn" {
  value = aws_dynamodb_table.llm_prompt_template.arn
}
