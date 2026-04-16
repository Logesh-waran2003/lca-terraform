variable "lob" {
  description = "Line of Business configuration block"
  type = object({
    name                 = string
    connect_instance_arn = string
    allowed_email_domain = string
    admin_email          = string
  })
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "account_id" {
  type = string
}

variable "dynamodb_expiration_in_days" {
  type    = number
  default = 90
}

variable "audio_recording_expiration_in_days" {
  type    = number
  default = 90
}

variable "is_sentiment_analysis_enabled" {
  type    = bool
  default = true
}

variable "sentiment_negative_threshold" {
  type    = number
  default = 0.9
}

variable "sentiment_positive_threshold" {
  type    = number
  default = 0.4
}

variable "end_of_call_transcript_summary" {
  type    = string
  default = "BEDROCK"
}

variable "bedrock_model_id" {
  type    = string
  default = "us.amazon.nova-lite-v1:0"
}

variable "comprehend_language_code" {
  type    = string
  default = "en"
}

variable "category_alert_regex" {
  type    = string
  default = ".*"
}

variable "cloudfront_price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "is_lex_agent_assist_enabled" {
  type    = bool
  default = false
}

variable "is_lambda_agent_assist_enabled" {
  type    = bool
  default = false
}
