variable "OPENAI_AUTH_TOKEN" {
  type        = string
  description = "API Key for OpenAI's ChatGPT"
  default     = ""
}

variable "GIT_USERNAME" {
  type        = string
  description = "Username for GitHub account"
  default     = ""
}

variable "GIT_AUTH_TOKEN" {
  type        = string
  description = "Token for GitHub account"
  default     = ""
}

variable "YOUTUBE_AUTH_TOKEN" {
  type        = string
  description = "Token for YouTube interaction"
  default     = ""
}