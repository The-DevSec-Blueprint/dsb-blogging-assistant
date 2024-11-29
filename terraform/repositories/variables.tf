variable "resource_prefix" {
  type        = string
  default     = "dsb-blogging-assistant"
  description = "Prefix for all resources"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}