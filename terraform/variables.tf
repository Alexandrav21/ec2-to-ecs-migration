variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ec2-ecs-migration"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "platform"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by the environment"
  type        = list(string)

  default = [
    "eu-west-2a",
    "eu-west-2b"
  ]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)

  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

variable "container_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 5000
}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "latest"
}

variable "desired_count" {
  description = "Initial desired number of ECS tasks"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 2
    error_message = "desired_count must be at least 2."
  }
}

variable "ecs_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "ecs_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks for autoscaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for autoscaling"
  type        = number
  default     = 4
}

variable "cpu_target" {
  description = "Target average ECS CPU utilization percentage"
  type        = number
  default     = 70
}

variable "memory_target" {
  description = "Target average ECS memory utilization percentage"
  type        = number
  default     = 75
}