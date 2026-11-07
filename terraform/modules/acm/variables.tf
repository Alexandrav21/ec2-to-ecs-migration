variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the ACM certificate"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID used for DNS validation"
  type        = string
}
