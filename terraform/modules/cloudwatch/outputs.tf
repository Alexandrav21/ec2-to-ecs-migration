output "ecs_log_group_name" {
  description = "CloudWatch log group name for ECS"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "ecs_log_group_arn" {
  description = "CloudWatch log group ARN for ECS"
  value       = aws_cloudwatch_log_group.ecs.arn
}

output "ecs_high_cpu_alarm_arn" {
  description = "ARN of the ECS high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_high_cpu.arn
}

output "alb_high_5xx_alarm_arn" {
  description = "ARN of the ALB high 5xx alarm"
  value       = aws_cloudwatch_metric_alarm.alb_high_5xx.arn
}