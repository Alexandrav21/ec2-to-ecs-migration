variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the Actions role"
  type        = string
  default     = "Alexandrav21/ec2-to-ecs-migration"
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the Actions role"
  type        = string
  default     = "main"
}

variable "aws_region" {
  description = "AWS region containing the ECR repository"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID containing the ECR repository"
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR repository name used by GitHub Actions"
  type        = string
}