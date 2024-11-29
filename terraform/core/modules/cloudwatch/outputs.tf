output "name" {
  value       = aws_cloudwatch_log_group.this.name
  description = "The name of the CloudWatch Log Group."
}

output "arn" {
  value       = aws_cloudwatch_log_group.this.arn
  description = "The ARN of the CloudWatch Log Group."
}
