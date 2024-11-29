output "name" {
  description = "Name of ECS Cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "task_definition_arn" {
  description = "ARN of Task Definition"
  value       = aws_ecs_task_definition.task_definition.arn
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_alb.alb.dns_name
}

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = aws_alb.alb.id
}

