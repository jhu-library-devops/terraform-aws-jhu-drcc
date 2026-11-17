# Security groups
resource "aws_security_group" "alb_sg" {
  name        = "${local.name}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = local.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "http_alb_ingress_rule" {
  for_each          = toset(var.alb_ingress_cidr_blocks)
  security_group_id = aws_security_group.alb_sg.id

  description = "Public HTTP traffic"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = each.key
}

resource "aws_vpc_security_group_ingress_rule" "https_alb_ingress_rule" {
  for_each          = toset(var.alb_ingress_cidr_blocks)
  security_group_id = aws_security_group.alb_sg.id

  description = "Public HTTPS traffic"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = each.key
}

resource "aws_vpc_security_group_egress_rule" "public_alb_to_angular" {
  security_group_id            = aws_security_group.alb_sg.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id

  description = "Public ALB to DSpace Angular targets"
  from_port   = 4000
  to_port     = 4000
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "public_alb_to_api" {
  security_group_id            = aws_security_group.alb_sg.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id

  description = "Public ALB to DSpace API targets"
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

resource "aws_security_group" "private_alb_sg" {
  name        = "private-${local.name}-alb-sg"
  description = "Security group for the private Application Load Balancer"
  vpc_id      = local.vpc_id

  tags = merge(local.tags, { Name = "private-${local.name}-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "api_private_alb_from_ecs" {
  security_group_id            = aws_security_group.private_alb_sg.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id

  description = "DSpace tasks to the private API listener"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "solr_private_alb_from_ecs" {
  security_group_id            = aws_security_group.private_alb_sg.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id

  description = "DSpace tasks to the private Solr listener"
  from_port   = 8983
  to_port     = 8983
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "private_alb_to_api" {
  security_group_id            = aws_security_group.private_alb_sg.id
  referenced_security_group_id = aws_security_group.ecs_service_sg.id

  description = "Private ALB to DSpace API targets"
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "${local.name}-ecs-service-sg"
  description = "Security group for shared DSpace ECS Fargate services"
  vpc_id      = local.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-ecs-service-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "angular_ecs_ingress_rule" {
  security_group_id = aws_security_group.ecs_service_sg.id

  description                  = "Public ALB to DSpace Angular"
  from_port                    = 4000
  to_port                      = 4000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "api_public_ecs_ingress_rule" {
  security_group_id = aws_security_group.ecs_service_sg.id

  description                  = "Public ALB to DSpace API"
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "api_private_ecs_ingress_rule" {
  security_group_id = aws_security_group.ecs_service_sg.id

  description                  = "Private ALB to DSpace API"
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.private_alb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_private_api" {
  security_group_id            = aws_security_group.ecs_service_sg.id
  referenced_security_group_id = aws_security_group.private_alb_sg.id

  description = "DSpace tasks to the private API listener"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_private_solr" {
  security_group_id            = aws_security_group.ecs_service_sg.id
  referenced_security_group_id = aws_security_group.private_alb_sg.id

  description = "DSpace tasks to the private Solr listener"
  from_port   = 8983
  to_port     = 8983
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_dns_udp" {
  security_group_id = aws_security_group.ecs_service_sg.id

  description = "VPC DNS resolution over UDP"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
  cidr_ipv4   = local.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_dns_tcp" {
  security_group_id = aws_security_group.ecs_service_sg.id

  description = "VPC DNS resolution over TCP"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"
  cidr_ipv4   = local.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_vpc_tcp" {
  for_each          = toset(var.ecs_vpc_tcp_egress_ports)
  security_group_id = aws_security_group.ecs_service_sg.id

  description = "DSpace tasks to VPC service port ${each.value}"
  from_port   = each.value
  to_port     = each.value
  ip_protocol = "tcp"
  cidr_ipv4   = local.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_any_ipv4_tcp" {
  for_each          = toset(var.ecs_any_ipv4_tcp_egress_ports)
  security_group_id = aws_security_group.ecs_service_sg.id

  description = "DSpace tasks to approved external TCP port ${each.value}"
  from_port   = each.value
  to_port     = each.value
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}
