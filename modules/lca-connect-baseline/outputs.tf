output "eventbridge_rule_arn" {
  value = aws_cloudwatch_event_rule.contact_events.arn
}

output "eventbridge_rule_name" {
  value = aws_cloudwatch_event_rule.contact_events.name
}
