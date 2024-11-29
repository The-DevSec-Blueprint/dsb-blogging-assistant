output "web_acl_arn" {
  value       = aws_wafv2_web_acl.this.arn
  description = "The ARN of the Web ACL."
}

output "rule_group_arn" {
  value       = aws_wafv2_rule_group.this.arn
  description = "The ARN of the rule group."
}
