output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "ecs_security_group_id" {
  description = "ECS task security group ID"
  value       = module.networking.ecs_security_group_id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.alb.alb_security_group_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = module.networking.nat_gateway_ids
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "target_group_arn" {
  description = "ALB target group ARN"
  value       = module.alb.target_group_arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "ecs_task_definition_arn" {
  description = "Current ECS task definition ARN"
  value       = module.ecs.task_definition_arn
}

output "ecs_log_group_name" {
  description = "CloudWatch log group name used by ECS"
  value       = module.cloudwatch.ecs_log_group_name
}