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

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = each.key
}

resource "aws_vpc_security_group_ingress_rule" "https_alb_ingress_rule" {
  for_each          = toset(var.alb_ingress_cidr_blocks)
  security_group_id = aws_security_group.alb_sg.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = each.key
}

resource "aws_vpc_security_group_egress_rule" "public_alb_egress" {
  security_group_id = aws_security_group.alb_sg.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_security_group" "private_alb_sg" {
  name        = "private-${local.name}-alb-sg"
  description = "Security group for the private Application Load Balancer"
  vpc_id      = local.vpc_id

  tags = merge(local.tags, { Name = "private-${local.name}-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "api_private_alb_ingress_rule" {
  for_each          = toset(var.private_subnet_cidrs)
  security_group_id = aws_security_group.private_alb_sg.id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = each.key
}

resource "aws_vpc_security_group_ingress_rule" "solr_private_alb_ingress_rule" {
  for_each          = toset(var.private_subnet_cidrs)
  security_group_id = aws_security_group.private_alb_sg.id

  from_port   = 8983
  to_port     = 8983
  ip_protocol = "tcp"
  cidr_ipv4   = each.key
}

resource "aws_vpc_security_group_egress_rule" "private_alb_egress" {
  security_group_id = aws_security_group.private_alb_sg.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "${local.name}-ecs-service-sg"
  description = "Security group for the ECS Fargate service"
  vpc_id      = local.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-ecs-service-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "angular_ecs_ingress_rule" {
  security_group_id = aws_security_group.ecs_service_sg.id

  from_port                    = 4000
  to_port                      = 4000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "api_public_ecs_ingress_rule" {
  security_group_id = aws_security_group.ecs_service_sg.id

  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "api_private_ecs_ingress_rule" {
  security_group_id = aws_security_group.ecs_service_sg.id

  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.private_alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "solr_ecs_ingress_rule" {
  security_group_id = aws_security_group.ecs_service_sg.id

  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.private_alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "solr_ecs_self_ingress_rule" {
  security_group_id = aws_security_group.ecs_service_sg.id

  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_service_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_service_egress" {
  security_group_id = aws_security_group.ecs_service_sg.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_security_group" "rds" {
  count       = var.deploy_database ? 1 : 0
  name        = "${local.name}-rds-sg"
  description = "Allow traffic to the RDS instance from the ECS service"
  vpc_id      = local.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-rds-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "db_ingress_rule" {
  count             = var.deploy_database ? 1 : 0
  security_group_id = aws_security_group.rds[0].id

  description                  = "Allow Postgres traffic from the ECS service"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_service_sg.id
}
