output "client_ssm_session" {
  description = "Client Instance SSM command"
  value       = "aws ssm start-session --region ${data.aws_region.current.name} --target ${module.client.aws_instance.id}"
}

output "client_private_ip" {
  description = "Client Private IP"
  value       = module.client.aws_instance.private_ip
}

output "client_private_dns" {
  description = "Client Private DNS name"
  value       = aws_route53_record.client.name
}

output "client_virtual_ip" {
  description = "Web Server Virtual IP"
  value       = one(aws_route53_record.client.records)
}

output "web_ssm_session" {
  description = "Client Instance SSM command"
  value       = "aws ssm start-session --region ${data.aws_region.current.name} --target ${module.web_server.aws_instance.id}"
}

output "web_private_ip" {
  description = "Web Server Private IP"
  value       = module.web_server.aws_instance.private_ip
}

output "web_private_dns" {
  description = "Web Server Private DNS name"
  value       = aws_route53_record.web.name
}

output "web_virtual_ip" {
  description = "Web Server Virtual IP"
  value       = one(aws_route53_record.web.records)
}