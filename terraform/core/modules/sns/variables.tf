variable "name" {
  description = "The name of the SNS topic."
  type        = string
}

variable "protocol" {
  description = "The protocol to use for the subscription (e.g., 'email', 'http', etc.)."
  type        = string
}

variable "endpoint" {
  description = "The endpoint to send notifications to (e.g., an email address or URL)."
  type        = string
}
