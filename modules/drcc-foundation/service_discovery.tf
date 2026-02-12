# Service Discovery Namespace
# CloudMap private DNS namespace for service discovery
resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "${var.project_name}.${var.environment}.local"
  vpc  = local.vpc_id
  tags = local.tags
}
