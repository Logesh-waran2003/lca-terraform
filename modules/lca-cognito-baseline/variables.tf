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

variable "admin_email" {
  description = "Admin user email address"
  type        = string
}

variable "allowed_email_domain" {
  description = "Allowed email domain for sign-up"
  type        = string
}

variable "cognito_authorized_role_arn" {
  description = "IAM role ARN for Cognito authorized users"
  type        = string
}

variable "agent_assist_unauth_role_arn" {
  description = "IAM role ARN for agent assist unauthenticated users"
  type        = string
}

variable "email_domain_verify_role_arn" {
  description = "IAM role ARN for the email domain verify Lambda"
  type        = string
}

variable "recordings_bucket_name" {
  description = "Name of the recordings S3 bucket"
  type        = string
}

variable "settings_parameter_name" {
  description = "Name of the SSM parameter for LCA settings"
  type        = string
}
