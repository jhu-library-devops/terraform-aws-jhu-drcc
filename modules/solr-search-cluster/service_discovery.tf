# Service Discovery for Solr and Zookeeper
# Note: Namespace is created in drcc-foundation module

# Data source to get private ALB network interfaces
data "aws_network_interfaces" "private_alb" {
  filter {
    name   = "description"
    values = ["ELB app/${var.private_alb_name}/*"]
  }

  filter {
    name   = "status"
    values = ["in-use"]
  }
}

# Get details of the first network interface
data "aws_network_interface" "private_alb_first" {
  id = element(data.aws_network_interfaces.private_alb.ids, 0)
}

# Individual service discovery services for each Solr node
resource "aws_service_discovery_service" "solr_individual" {
  count = var.solr_node_count
  name  = "solr-${count.index + 1}"

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 60
      type = "A"
    }
  }

  tags = local.tags
}

# Individual service discovery services for each Zookeeper instance
resource "aws_service_discovery_service" "zookeeper_individual" {
  count = var.deploy_zookeeper ? var.zookeeper_task_count : 0
  name  = "${local.zk_service_name}-${count.index + 1}"

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = local.tags
}

# Collective service discovery for Solr to connect to Zookeeper ensemble
resource "aws_service_discovery_service" "zookeeper" {
  count = var.deploy_zookeeper ? 1 : 0
  name  = local.zk_service_name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = local.tags
}

# Service discovery for Solr ALB endpoint
resource "aws_service_discovery_service" "solr_alb" {
  name = "solr"

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = local.tags
}

# Register ALB IP to solr service discovery
resource "aws_service_discovery_instance" "solr_alb" {
  instance_id = "solr-alb"
  service_id  = aws_service_discovery_service.solr_alb.id

  attributes = {
    AWS_INSTANCE_IPV4 = data.aws_network_interface.private_alb_first.private_ip
  }
}
