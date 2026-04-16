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

variable "lambda_functions" {
  description = "Map of Lambda function configurations"
  type = map(object({
    function_name = string
    role_key      = string
    runtime       = string
    architectures = list(string)
    memory_size   = number
    timeout       = number
    filename      = string
    handler       = string
    use_layer     = bool
    environment   = map(string)
  }))
}

variable "role_arns" {
  description = "Map of IAM role ARNs keyed by role logical name"
  type        = map(string)
}

variable "consumer_arn" {
  description = "ARN of the Kinesis enhanced fan-out consumer"
  type        = string
}

variable "connect_instance_arn" {
  description = "ARN of the Amazon Connect instance"
  type        = string
  default     = ""
}

variable "call_data_stream_arn" {
  description = "ARN of the Kinesis call data stream"
  type        = string
  default     = ""
}
