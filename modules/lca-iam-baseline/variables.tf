variable "lob" {
  description = "Line of Business name"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "event_sourcing_table_arn" {
  description = "ARN of the DynamoDB event sourcing table"
  type        = string
}

variable "llm_prompt_table_arn" {
  description = "ARN of the DynamoDB LLM prompt template table"
  type        = string
}

variable "lca_settings_parameter_arn" {
  description = "ARN of the SSM parameter for LCA settings"
  type        = string
}

variable "recordings_bucket_arn" {
  description = "ARN of the recordings S3 bucket"
  type        = string
}

variable "connect_instance_arn" {
  description = "ARN of the Amazon Connect instance"
  type        = string
}

variable "call_data_stream_arn" {
  description = "ARN of the Kinesis call data stream"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS category alert topic"
  type        = string
}
