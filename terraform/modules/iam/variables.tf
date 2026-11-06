variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
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

variable "github_oidc_subject" {
  description = "GitHub OIDC subject allowed to assume the GitHub Actions role"
  type        = string
}