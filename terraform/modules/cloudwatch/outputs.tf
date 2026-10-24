output "ecs_log_group_name" {
  description = "CloudWatch log group name for ECS"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "ecs_log_group_arn" {
  description = "CloudWatch log group ARN for ECS"
  value       = aws_cloudwatch_log_group.ecs.arn
}