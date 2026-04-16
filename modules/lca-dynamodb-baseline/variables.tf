variable "lob" {
  description = "Line of Business name"
  type        = string
}

variable "dynamodb_expiration_in_days" {
  description = "TTL expiration in days for DynamoDB records"
  type        = number
  default     = 90
}
