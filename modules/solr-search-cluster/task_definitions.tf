# Task Definition Resources for Solr and Zookeeper
#
# This file contains separate, independent task definition resources for:
# - Solr nodes (one per node with node-specific configuration)
# - Zookeeper nodes (one per node with node-specific configuration)
#
# Task definitions are conditionally created based on use_external_task_definitions flag.
# When use_external_task_definitions = false, these resources are created.
# When use_external_task_definitions = true, external ARNs are used instead.

# Solr Node Task Definitions
# Creates separate task definition for each Solr node with node-specific configuration
resource "aws_ecs_task_definition" "solr_node" {
  count = var.use_external_task_definitions ? 0 : var.solr_node_count

  family                   = "${var.organization}-${var.environment}-solr-${count.index + 1}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.solr_cpu
  memory                   = var.solr_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  # EFS volume for Solr data with node-specific root directory
  volume {
    name = "solr-data"
    efs_volume_configuration {
      file_system_id     = var.solr_efs_file_system_id
      root_directory     = "/solr-${count.index + 1}"
      transit_encryption = "ENABLED"
    }
  }

  container_definitions = jsonencode([{
    name      = "${var.organization}-${var.environment}-solr-${count.index + 1}"
    image     = var.solr_image
    cpu       = var.solr_cpu
    memory    = var.solr_memory
    essential = true

    portMappings = [{
      containerPort = 8983
      protocol      = "tcp"
    }]

    # Node-specific SOLR_HOST environment variable
    environment = [
      {
        name  = "SOLR_HOST"
        value = "solr-${count.index + 1}.${var.service_discovery_namespace_name}"
      },
      {
        name  = "SOLR_OPTS"
        value = var.solr_opts
      }
    ]

    # Secrets from SSM parameters
    secrets = [
      {
        name      = "ZK_HOST"
        valueFrom = var.zookeeper_host_ssm_arn
      },
      {
        name      = "DB_CREDENTIALS_SECRET_ARN"
        valueFrom = var.db_credentials_ssm_arn
      }
    ]

    # Mount EFS volume
    mountPoints = [{
      sourceVolume  = "solr-data"
      containerPath = "/var/solr/data"
      readOnly      = false
    }]

    # Health check
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8983/solr/admin/ping || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }

    # Resource limits
    ulimits = [{
      name      = "nofile"
      softLimit = 65000
      hardLimit = 65000
    }]

    # Logging configuration
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.organization}-${var.environment}-solr"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "solr-${count.index + 1}"
      }
    }
  }])

  # Lifecycle policy to support CI/CD image updates without Terraform drift
  lifecycle {
    ignore_changes = [container_definitions]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.organization}-${var.environment}-solr-${count.index + 1}"
      Environment = var.environment
      Service     = "solr"
      Node        = tostring(count.index + 1)
    }
  )
}


# Zookeeper Node Task Definitions
# Creates separate task definition for each Zookeeper node with node-specific configuration
resource "aws_ecs_task_definition" "zookeeper_node" {
  count = var.deploy_zookeeper && !var.use_external_task_definitions ? var.zookeeper_task_count : 0

  family                   = "${var.organization}-${var.environment}-zookeeper-${count.index + 1}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.zookeeper_cpu
  memory                   = var.zookeeper_memory
  execution_role_arn       = var.ecs_task_execution_role_arn

  # EFS volume for Zookeeper data with node-specific root directory
  volume {
    name = "zookeeper-data"
    efs_volume_configuration {
      file_system_id     = var.zookeeper_efs_file_system_id
      root_directory     = "/zookeeper-${count.index + 1}"
      transit_encryption = "ENABLED"
    }
  }

  container_definitions = jsonencode([{
    name      = "${var.organization}-${var.environment}-zookeeper-${count.index + 1}"
    image     = var.zookeeper_image
    cpu       = var.zookeeper_cpu
    memory    = var.zookeeper_memory
    essential = true

    portMappings = [
      { containerPort = 2181, protocol = "tcp" }, # Client port
      { containerPort = 2888, protocol = "tcp" }, # Peer communication
      { containerPort = 3888, protocol = "tcp" }, # Leader election
      { containerPort = 8080, protocol = "tcp" }  # Admin server
    ]

    # Node-specific ZOO_MY_ID and ensemble configuration
    environment = [
      {
        name  = "ZOO_MY_ID"
        value = tostring(count.index + 1)
      },
      {
        name = "ZOO_SERVERS"
        # Construct ensemble config: server.1=zookeeper-1.namespace:2888:3888;2181 server.2=...
        value = join(" ", [
          for i in range(var.zookeeper_task_count) :
          "server.${i + 1}=zookeeper-${i + 1}.${var.service_discovery_namespace_name}:2888:3888;2181"
        ])
      },
      {
        name  = "JVMFLAGS"
        value = var.zookeeper_jvmflags
      }
    ]

    # Mount EFS volume
    mountPoints = [{
      sourceVolume  = "zookeeper-data"
      containerPath = "/data"
      readOnly      = false
    }]

    # Health check
    healthCheck = {
      command     = ["CMD-SHELL", "echo ruok | nc localhost 2181 | grep imok || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }

    # Resource limits
    ulimits = [{
      name      = "nofile"
      softLimit = 100000
      hardLimit = 100000
    }]

    # Logging configuration
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.organization}-${var.environment}-zookeeper"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "zookeeper-${count.index + 1}"
      }
    }
  }])

  # Lifecycle policy to support CI/CD image updates without Terraform drift
  lifecycle {
    ignore_changes = [container_definitions]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.organization}-${var.environment}-zookeeper-${count.index + 1}"
      Environment = var.environment
      Service     = "zookeeper"
      Node        = tostring(count.index + 1)
    }
  )
}
