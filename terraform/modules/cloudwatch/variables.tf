variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name used by the service alarm"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name used by the service alarm"
  type        = string
}

variable "alb_arn_suffix" {
  description = "Application Load Balancer ARN suffix used by the 5xx alarm"
  type        = string
}

variable "ecs_cpu_alarm_threshold" {
  description = "CPU utilisation percentage that triggers the ECS alarm"
  type        = number
  default     = 80
}

variable "alb_5xx_alarm_threshold" {
  description = "Number of ALB 5xx responses in one evaluation period that triggers the alarm"
  type        = number
  default     = 5
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix used by the application 5xx and latency alarms"
  type        = string
}

variable "target_5xx_alarm_threshold" {
  description = "Number of application (target) 5xx responses in one evaluation period that triggers the alarm"
  type        = number
  default     = 5
}

variable "target_p95_latency_alarm_threshold" {
  description = "p95 target response time in seconds that triggers the latency alarm"
  type        = number
  default     = 1
}