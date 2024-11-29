# Terraform Environment Variables
variable "GIT_USERNAME" {}
variable "GIT_AUTH_TOKEN" {}
variable "YOUTUBE_AUTH_TOKEN" {}
variable "PROXY_USERNAME" {}
variable "PROXY_PASSWORD" {}
variable "EMAIL_ADDRESS" {}
variable "YOUTUBE_TOPIC_URL" {}
variable "YOUTUBE_CHANNEL_NAME" {}
variable "BLOG_GIT_REPO_URL" {}

# Project Variables
variable "resource_prefix" {
  type        = string
  default     = "dsb-blogging-assistant"
  description = "Prefix for all resources"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}