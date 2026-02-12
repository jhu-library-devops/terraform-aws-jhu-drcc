# Security group for Solr service
resource "aws_security_group" "solr_service_sg" {
  name        = "${local.name}-solr-sg"
  description = "Security group for the Solr ECS service"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-solr-sg" })
}

# Solr HTTP port (8983) - allow access from ECS security group
resource "aws_vpc_security_group_ingress_rule" "solr_http_ingress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.ecs_security_group_id
}

# Solr HTTP port (8983) - allow access from private ALB
resource "aws_vpc_security_group_ingress_rule" "solr_http_alb_ingress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.private_alb_security_group_id
}

# Solr HTTP port (8983) - allow Solr nodes to communicate with each other
resource "aws_vpc_security_group_ingress_rule" "solr_http_self_ingress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

# Solr HTTP port (8983) - allow access from canary for health checks
resource "aws_vpc_security_group_ingress_rule" "solr_http_canary_ingress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.canary.id
}

# Solr egress rules - specific ports for security
resource "aws_vpc_security_group_egress_rule" "solr_zookeeper_egress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port   = 2181
  to_port     = 2181
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "solr_dns_egress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "solr_https_egress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "solr_nfs_egress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port   = 2049
  to_port     = 2049
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

# Solr to ALB communication (for solr.dspace-*.local DNS)
resource "aws_vpc_security_group_egress_rule" "solr_alb_egress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.private_alb_security_group_id
}

# Solr to Solr communication (for replica creation and cluster operations)
resource "aws_vpc_security_group_egress_rule" "solr_self_egress" {
  security_group_id = aws_security_group.solr_service_sg.id

  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

# Security groups for Zookeeper (Solr-specific)
resource "aws_security_group" "zookeeper_service_sg" {
  count       = var.deploy_zookeeper ? 1 : 0
  name        = "${local.name}-zookeeper-sg"
  description = "Security group for the Zookeeper ECS service"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-zookeeper-sg" })
}

# Client connections (port 2181) - allow from baseline ECS service
resource "aws_vpc_security_group_ingress_rule" "zk_client_ingress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  from_port                    = 2181
  to_port                      = 2181
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.ecs_security_group_id
}

# Client connections (port 2181) - allow from Solr service
resource "aws_vpc_security_group_ingress_rule" "zk_client_solr_ingress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  from_port                    = 2181
  to_port                      = 2181
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

# Ensemble communication - follower to leader (port 2888)
resource "aws_vpc_security_group_ingress_rule" "zk_follower_ingress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  from_port                    = 2888
  to_port                      = 2888
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.zookeeper_service_sg[0].id
}

# Ensemble communication - leader election (port 3888)
resource "aws_vpc_security_group_ingress_rule" "zk_election_ingress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  from_port                    = 3888
  to_port                      = 3888
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.zookeeper_service_sg[0].id
}

resource "aws_vpc_security_group_egress_rule" "zk_egress_rule" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
