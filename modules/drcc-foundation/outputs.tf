# VPC and Networking Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = local.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.private_subnet_ids
}

# ECS Cluster Outputs
output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# Security Group Outputs
output "ecs_security_group_id" {
  description = "The ID of the ECS service security group"
  value       = aws_security_group.ecs_service_sg.id
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "private_alb_security_group_id" {
  description = "The ID of the private ALB security group"
  value       = aws_security_group.private_alb_sg.id
}

# Load Balancer Outputs
output "alb_arn" {
  description = "The ARN of the public Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the public Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The zone ID of the public Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the public Application Load Balancer"
  value       = aws_lb.main.arn_suffix
}

output "private_alb_arn" {
  description = "The ARN of the private Application Load Balancer"
  value       = aws_lb.private.arn
}

output "private_alb_dns_name" {
  description = "The DNS name of the private Application Load Balancer"
  value       = aws_lb.private.dns_name
}

output "private_alb_arn_suffix" {
  description = "The ARN suffix of the private Application Load Balancer"
  value       = aws_lb.private.arn_suffix
}

output "private_alb_name" {
  description = "The name of the private Application Load Balancer"
  value       = aws_lb.private.name
}

# Listener Outputs
output "alb_https_listener_arn" {
  description = "The ARN of the public ALB HTTPS listener"
  value       = aws_lb_listener.https.arn
}

output "alb_http_listener_arn" {
  description = "The ARN of the public ALB HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "private_alb_listener_arn" {
  description = "The ARN of the private ALB HTTP listener (port 80)"
  value       = aws_lb_listener.private_http.arn
}

output "private_solr_listener_arn" {
  description = "The ARN of the private Solr listener (port 8983)"
  value       = aws_lb_listener.private_solr.arn
}

# IAM Role Outputs
output "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "The ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

# Database Outputs
output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = module.dspace_app_services.db_instance_id
}

output "db_instance_identifier" {
  description = "The identifier of the RDS instance"
  value       = module.dspace_app_services.db_instance_identifier
}

output "db_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.dspace_app_services.db_instance_endpoint
}

output "db_credentials_secret_arn" {
  description = "The ARN of the database credentials secret"
  value       = module.dspace_app_services.db_credentials_secret_arn
}

# Route53 Outputs
output "private_zone_id" {
  description = "The ID of the private Route53 zone"
  value       = aws_route53_zone.private_dspace_zone.zone_id
}

output "private_zone_name" {
  description = "The name of the private Route53 zone"
  value       = aws_route53_zone.private_dspace_zone.name
}

# Monitoring Outputs
output "sns_topic_arn" {
  description = "The ARN of the SNS topic for alarms"
  value       = var.enable_enhanced_monitoring ? aws_sns_topic.alarms[0].arn : null
}

# WAF Outputs
output "waf_web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

# Service Discovery Outputs
output "service_discovery_namespace_id" {
  description = "The ID of the CloudMap service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "service_discovery_namespace_name" {
  description = "The name of the CloudMap service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "service_discovery_namespace_arn" {
  description = "The ARN of the CloudMap service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.arn
}

# EFS outputs moved to dspace-app-services module

# ACM Certificate Outputs
output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate (created or provided)"
  value       = local.ssl_certificate_arn
}

output "acm_certificate_dns_validation_records" {
  description = "DNS validation records for the ACM certificate. Create these records in your DNS provider to complete validation."
  value = var.create_ssl_certificate ? [
    for dvo in aws_acm_certificate.main[0].domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ] : []
}
