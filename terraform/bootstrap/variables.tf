variable "aws_region" {
  description = "AWS region for the Terraform state bucket"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming"
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