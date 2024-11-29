output "name" {
  value       = aws_ecr_repository.this.name
  description = "The name of the created ECR repository."
}

output "arn" {
  value       = aws_ecr_repository.this.arn
  description = "The ARN of the created ECR repository."
}
