variable "lob" {
  description = "Line of Business name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}

variable "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
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

variable "appsync_cwl_role_arn" {
  description = "IAM role ARN for AppSync CloudWatch Logs"
  type        = string
}

variable "appsync_dynamodb_role_arn" {
  description = "IAM role ARN for AppSync DynamoDB access"
  type        = string
}
