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

variable "category_alert_regex" {
  description = "Regex pattern for category alerts"
  type        = string
}

variable "llm_prompt_table_name" {
  description = "Name of the LLM prompt template DynamoDB table"
  type        = string
}

variable "update_settings_role_arn" {
  description = "IAM role ARN for the update-lca-settings Lambda"
  type        = string
}

variable "llm_prompt_upload_role_arn" {
  description = "IAM role ARN for the llm-prompt-upload Lambda"
  type        = string
}
