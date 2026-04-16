variable "lob" {
  description = "Line of Business name"
  type        = string
}

variable "audio_recording_expiration_in_days" {
  description = "Number of days before audio recordings expire"
  type        = number
  default     = 90
}
