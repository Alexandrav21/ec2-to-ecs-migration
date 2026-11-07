output "fqdn" {
  description = "Fully qualified domain name for the application"
  value       = aws_route53_record.app.fqdn
}
