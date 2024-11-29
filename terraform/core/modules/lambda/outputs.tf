output "arn" {
  value       = aws_lambda_function.this.arn
  description = "The ARN of the Lambda function."
}

output "name" {
  value       = aws_lambda_function.this.function_name
  description = "The name of the Lambda function."
}
output "function_url" {
  value       = length(aws_lambda_function_url.this) > 0 ? aws_lambda_function_url.this[0].function_url : ""
  description = "The URL of the Lambda function."
}
