variable "location" {
  description = "Azure region for deployment."
  type        = string
  default     = "Central India"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"
}