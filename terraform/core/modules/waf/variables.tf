variable "acl_name" {
  description = "The name of the Web ACL."
  type        = string
}

variable "acl_description" {
  description = "Description for the Web ACL."
  type        = string
}

variable "acl_metric_name" {
  description = "Metric name for the Web ACL."
  type        = string
}

variable "scope" {
  description = "Scope of the Web ACL (REGIONAL or CLOUDFRONT)."
  type        = string
  default     = "REGIONAL"
}

variable "rule_group_name" {
  description = "The name of the WAFv2 rule group."
  type        = string
}

variable "rule_group_metric_name" {
  description = "Metric name for the rule group."
  type        = string
}

variable "rule_group_capacity" {
  description = "Capacity units for the WAF rule group."
  type        = number
}

variable "rules" {
  description = "List of rules for the rule group."
  type        = any
}

variable "resource_arn" {
  description = "ARN of the resource (e.g., ALB) to associate with the Web ACL."
  type        = string
}
