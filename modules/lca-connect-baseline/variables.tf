variable "lob" {
  description = "Line of Business name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "connect_instance_arn" {
  description = "ARN of the Amazon Connect instance"
  type        = string
}

variable "call_data_stream_name" {
  description = "Name of the Kinesis call data stream"
  type        = string
}

variable "call_data_stream_arn" {
  description = "ARN of the Kinesis call data stream"
  type        = string
}

variable "event_sourcing_table_name" {
  description = "Name of the DynamoDB event sourcing table"
  type        = string
}

variable "event_sourcing_table_arn" {
  description = "ARN of the DynamoDB event sourcing table"
  type        = string
}

variable "call_event_processor_role_name" {
  description = "Name of the call event processor IAM role"
  type        = string
}

variable "contact_event_processor_role_arn" {
  description = "ARN of the contact event processor IAM role"
  type        = string
}

variable "associate_instance_function_name" {
  description = "Name of the associate-instance Lambda function"
  type        = string
}

variable "contact_event_processor_function_arn" {
  description = "ARN of the contact-event-processor Lambda function"
  type        = string
}
