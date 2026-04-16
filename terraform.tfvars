lob = {
  name                 = "wellington"
  connect_instance_arn = "arn:aws:connect:us-east-1:025066253495:instance/REPLACE_ME"
  allowed_email_domain = "wellington.com"
  admin_email          = "admin@wellington.com"
}

aws_region = "us-east-1"
account_id = "025066253495"

dynamodb_expiration_in_days        = 90
audio_recording_expiration_in_days = 90
is_sentiment_analysis_enabled      = true
sentiment_negative_threshold       = 0.9
sentiment_positive_threshold       = 0.4
end_of_call_transcript_summary     = "BEDROCK"
bedrock_model_id                   = "us.amazon.nova-lite-v1:0"
comprehend_language_code           = "en"
category_alert_regex               = ".*"
cloudfront_price_class             = "PriceClass_100"
is_lex_agent_assist_enabled        = false
is_lambda_agent_assist_enabled     = false
