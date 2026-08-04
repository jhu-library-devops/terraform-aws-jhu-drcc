resource "aws_security_group" "mcp" {
  name_prefix = "${local.name_prefix}-task-"
  description = "Repository MCP Fargate tasks for ${var.environment}"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${local.name_prefix}-task" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "mcp_from_public_alb" {
  security_group_id            = aws_security_group.mcp.id
  referenced_security_group_id = var.public_alb_security_group_id
  description                  = "MCP application traffic from the public ALB"
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "public_alb_to_mcp" {
  security_group_id            = var.public_alb_security_group_id
  referenced_security_group_id = aws_security_group.mcp.id
  description                  = "Public ALB traffic to MCP targets"
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "mcp_to_jscholarship_solr" {
  security_group_id            = aws_security_group.mcp.id
  referenced_security_group_id = var.jscholarship_solr_security_group_id
  description                  = "JScholarship Solr search collection"
  from_port                    = var.jscholarship_solr_port
  to_port                      = var.jscholarship_solr_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "jscholarship_solr_from_mcp" {
  security_group_id            = var.jscholarship_solr_security_group_id
  referenced_security_group_id = aws_security_group.mcp.id
  description                  = "Repository MCP Solr read access"
  from_port                    = var.jscholarship_solr_port
  to_port                      = var.jscholarship_solr_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "mcp_to_jscholarship_api" {
  security_group_id            = aws_security_group.mcp.id
  referenced_security_group_id = var.jscholarship_api_security_group_id
  description                  = "JScholarship API endpoint"
  from_port                    = var.jscholarship_api_port
  to_port                      = var.jscholarship_api_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "jscholarship_api_from_mcp" {
  security_group_id            = var.jscholarship_api_security_group_id
  referenced_security_group_id = aws_security_group.mcp.id
  description                  = "Repository MCP API access"
  from_port                    = var.jscholarship_api_port
  to_port                      = var.jscholarship_api_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "mcp_to_jhrdr_solr" {
  count = var.jhrdr_solr_security_group_id != null ? 1 : 0

  security_group_id            = aws_security_group.mcp.id
  referenced_security_group_id = var.jhrdr_solr_security_group_id
  description                  = "JHRDR Solr collection"
  from_port                    = var.jhrdr_solr_port
  to_port                      = var.jhrdr_solr_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "jhrdr_solr_from_mcp" {
  count = var.jhrdr_solr_security_group_id != null ? 1 : 0

  security_group_id            = var.jhrdr_solr_security_group_id
  referenced_security_group_id = aws_security_group.mcp.id
  description                  = "Repository MCP JHRDR Solr read access"
  from_port                    = var.jhrdr_solr_port
  to_port                      = var.jhrdr_solr_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "mcp_to_jhrdr_api" {
  count = var.jhrdr_api_security_group_id != null ? 1 : 0

  security_group_id            = aws_security_group.mcp.id
  referenced_security_group_id = var.jhrdr_api_security_group_id
  description                  = "JHRDR Native API"
  from_port                    = var.jhrdr_api_port
  to_port                      = var.jhrdr_api_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "jhrdr_api_from_mcp" {
  count = var.jhrdr_api_security_group_id != null ? 1 : 0

  security_group_id            = var.jhrdr_api_security_group_id
  referenced_security_group_id = aws_security_group.mcp.id
  description                  = "Repository MCP JHRDR API access"
  from_port                    = var.jhrdr_api_port
  to_port                      = var.jhrdr_api_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "mcp_to_https" {
  security_group_id = aws_security_group.mcp.id
  description       = "AWS APIs and public HTTPS repository endpoints"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "mcp_to_dns_udp" {
  security_group_id = aws_security_group.mcp.id
  description       = "VPC DNS resolution over UDP"
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "mcp_to_dns_tcp" {
  security_group_id = aws_security_group.mcp.id
  description       = "VPC DNS resolution over TCP"
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
}
