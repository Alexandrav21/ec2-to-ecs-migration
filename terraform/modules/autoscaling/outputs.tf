output "scalable_target_id" {
  description = "ECS Application Auto Scaling target ID"
  value       = aws_appautoscaling_target.ecs.id
}

output "cpu_scaling_policy_arn" {
  description = "CPU target tracking scaling policy ARN"
  value       = aws_appautoscaling_policy.ecs_cpu.arn
}

output "memory_scaling_policy_arn" {
  description = "Memory target tracking scaling policy ARN"
  value       = aws_appautoscaling_policy.ecs_memory.arn
}