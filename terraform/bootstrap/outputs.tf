output "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "github_actions_terraform_role_arn" {
  description = "ARN of the GitHub Actions Terraform role"
  value       = aws_iam_role.github_actions_terraform.arn
}