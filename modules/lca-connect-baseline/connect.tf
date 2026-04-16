resource "aws_cloudwatch_event_rule" "contact_events" {
  name        = "contact-event-rule-${var.lob}"
  description = "Triggered by CONNECTED_TO_AGENT Connect Contact events"

  event_pattern = jsonencode({
    detail-type = ["Amazon Connect Contact Event"]
    source      = ["aws.connect"]
    detail = {
      instanceArn = [var.connect_instance_arn]
      channel     = ["VOICE"]
      eventType   = ["CONNECTED_TO_AGENT"]
    }
  })

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_cloudwatch_event_target" "contact_processor" {
  rule = aws_cloudwatch_event_rule.contact_events.name
  arn  = var.contact_event_processor_function_arn
}

resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.contact_event_processor_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.contact_events.arn
}

resource "aws_iam_role_policy" "connect_policy" {
  name = "ConnectPolicy-${var.lob}"
  role = var.call_event_processor_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["connect:GetContactAttributes"]
      Resource = "${var.connect_instance_arn}/contact/*"
    }]
  })
}
