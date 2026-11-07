output "alb_id" {
  description = "Application Load Balancer ID"
  value       = aws_lb.app.id
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.app.arn
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the Application Load Balancer"
  value       = aws_lb.app.zone_id
}

output "target_group_arn" {
  description = "Application target group ARN"
  value       = aws_lb_target_group.app.arn
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "alb_arn_suffix" {
  description = "ARN suffix of the application load balancer"
  value       = aws_lb.app.arn_suffix
}