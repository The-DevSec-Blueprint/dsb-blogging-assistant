output "arn" {
  description = "The ARN of the SNS topic."
  value       = aws_sns_topic.this.arn
}

output "id" {
  description = "The ID of the SNS subscription."
  value       = aws_sns_topic_subscription.this.id
}
