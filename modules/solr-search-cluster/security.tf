data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Security group for Solr service
resource "aws_security_group" "solr_service_sg" {
  name        = "${local.name}-solr-sg"
  description = "Security group for the Solr ECS service"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-solr-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "solr_http_ingress" {
  security_group_id = aws_security_group.solr_service_sg.id

  description                  = "DSpace tasks to Solr"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.ecs_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_solr" {
  security_group_id = var.ecs_security_group_id

  description                  = "DSpace tasks to Solr"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "solr_http_alb_ingress" {
  security_group_id = aws_security_group.solr_service_sg.id

  description                  = "Private ALB to Solr targets"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.private_alb_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "private_alb_to_solr" {
  security_group_id = var.private_alb_security_group_id

  description                  = "Private ALB to Solr targets"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "private_alb_from_solr" {
  security_group_id = var.private_alb_security_group_id

  description                  = "Solr nodes to the private Solr listener"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "solr_http_self_ingress" {
  security_group_id = aws_security_group.solr_service_sg.id

  description                  = "Solr node peer traffic"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "solr_http_canary_ingress" {
  security_group_id = aws_security_group.solr_service_sg.id

  description                  = "Synthetics canary health checks"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.canary.id
}

resource "aws_vpc_security_group_egress_rule" "canary_to_solr" {
  security_group_id = aws_security_group.canary.id

  description                  = "Synthetics canary health checks"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

resource "aws_vpc_security_group_egress_rule" "canary_dns_udp" {
  security_group_id = aws_security_group.canary.id

  description = "VPC DNS resolution over UDP"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "canary_dns_tcp" {
  security_group_id = aws_security_group.canary.id

  description = "VPC DNS resolution over TCP"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "canary_https" {
  security_group_id = aws_security_group.canary.id

  description = "CloudWatch and S3 APIs"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "solr_zookeeper_internal_egress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.solr_service_sg.id

  description                  = "Solr clients to the managed Zookeeper ensemble"
  from_port                    = 2181
  to_port                      = 2181
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.zookeeper_service_sg[0].id
}

resource "aws_vpc_security_group_egress_rule" "solr_zookeeper_external_egress" {
  for_each = var.deploy_zookeeper ? toset([]) : toset(
    length(var.external_zookeeper_cidr_blocks) > 0 ? var.external_zookeeper_cidr_blocks : [data.aws_vpc.selected.cidr_block]
  )

  security_group_id = aws_security_group.solr_service_sg.id
  description       = "Solr clients to an externally managed Zookeeper ensemble"
  from_port         = 2181
  to_port           = 2181
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "solr_dns_udp" {
  security_group_id = aws_security_group.solr_service_sg.id

  description = "VPC DNS resolution over UDP"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "solr_dns_tcp" {
  security_group_id = aws_security_group.solr_service_sg.id

  description = "VPC DNS resolution over TCP"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "solr_https" {
  security_group_id = aws_security_group.solr_service_sg.id

  description = "ECR, CloudWatch, Secrets Manager, and ECS Exec APIs"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "solr_nfs" {
  security_group_id = aws_security_group.solr_service_sg.id

  description                  = "Solr data storage on EFS"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_efs.id
}

resource "aws_vpc_security_group_egress_rule" "solr_alb_egress" {
  security_group_id = aws_security_group.solr_service_sg.id

  description                  = "Solr nodes to the private Solr listener"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.private_alb_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "solr_self_egress" {
  security_group_id = aws_security_group.solr_service_sg.id

  description                  = "Solr node peer traffic"
  from_port                    = 8983
  to_port                      = 8983
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

# Security group for the managed Zookeeper ensemble
resource "aws_security_group" "zookeeper_service_sg" {
  count       = var.deploy_zookeeper ? 1 : 0
  name        = "${local.name}-zookeeper-sg"
  description = "Security group for the Zookeeper ECS service"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-zookeeper-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "zk_client_solr_ingress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  description                  = "Solr clients to Zookeeper"
  from_port                    = 2181
  to_port                      = 2181
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.solr_service_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "zk_follower_ingress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  description                  = "Zookeeper follower-to-leader traffic"
  from_port                    = 2888
  to_port                      = 2888
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.zookeeper_service_sg[0].id
}

resource "aws_vpc_security_group_egress_rule" "zk_follower_egress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  description                  = "Zookeeper follower-to-leader traffic"
  from_port                    = 2888
  to_port                      = 2888
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.zookeeper_service_sg[0].id
}

resource "aws_vpc_security_group_ingress_rule" "zk_election_ingress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  description                  = "Zookeeper leader election traffic"
  from_port                    = 3888
  to_port                      = 3888
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.zookeeper_service_sg[0].id
}

resource "aws_vpc_security_group_egress_rule" "zk_election_egress" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  description                  = "Zookeeper leader election traffic"
  from_port                    = 3888
  to_port                      = 3888
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.zookeeper_service_sg[0].id
}

resource "aws_vpc_security_group_egress_rule" "zk_nfs" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  description                  = "Zookeeper data storage on EFS"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.zookeeper_efs[0].id
}

resource "aws_vpc_security_group_egress_rule" "zk_dns_udp" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  description = "VPC DNS resolution over UDP"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "zk_dns_tcp" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  description = "VPC DNS resolution over TCP"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "zk_https" {
  count             = var.deploy_zookeeper ? 1 : 0
  security_group_id = aws_security_group.zookeeper_service_sg[0].id

  description = "ECR, CloudWatch, and ECS Exec APIs"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

# Preserve state addresses for one-to-one rule renames during upgrades.
moved {
  from = aws_vpc_security_group_egress_rule.solr_dns_egress
  to   = aws_vpc_security_group_egress_rule.solr_dns_udp
}

moved {
  from = aws_vpc_security_group_egress_rule.solr_https_egress
  to   = aws_vpc_security_group_egress_rule.solr_https
}

moved {
  from = aws_vpc_security_group_egress_rule.solr_nfs_egress
  to   = aws_vpc_security_group_egress_rule.solr_nfs
}
