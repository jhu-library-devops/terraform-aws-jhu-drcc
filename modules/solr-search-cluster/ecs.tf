# ECS task definitions and services for Solr and Zookeeper
resource "aws_cloudwatch_log_group" "solr_fargate" {
  name = "/ecs/${var.environment}/dspace/solr"
  tags = local.tags
}

resource "aws_cloudwatch_log_group" "zookeeper_fargate" {
  count = var.deploy_zookeeper ? var.zookeeper_task_count : 0
  name  = "/ecs/${var.environment}/dspace/zookeeper-${count.index + 1}"
  tags  = local.tags
}

# Solr task definitions for individual nodes (conditional)
resource "aws_ecs_task_definition" "solr_fargate_td" {
  count                    = var.use_external_task_definitions ? 0 : var.solr_node_count
  family                   = "${local.name}-solr-${count.index + 1}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.solr_cpu
  memory                   = var.solr_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  # EFS Volume for Solr data persistence
  volume {
    name = "solr-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.solr_data.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.solr_data.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name   = "solr-container"
      image  = var.solr_image_override != null ? var.solr_image_override : "${aws_ecr_repository.repositories[local.solr_image_name].repository_url}:${var.solr_image_tag}"
      cpu    = var.solr_cpu
      memory = var.solr_memory

      essential   = true
      stopTimeout = 120

      portMappings = [
        {
          containerPort = 8983
          hostPort      = 8983
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "solr-data"
          containerPath = "/var/solr/data"
          readOnly      = false
        }
      ]

      linuxParameters = {
        initProcessEnabled = true
      }

      environment = [
        {
          name  = "SOLR_HOST"
          value = "solr-${count.index + 1}.${local.private_dns_namespace}"
        },
        {
          name  = "SOLR_OPTS"
          value = "-Dsolr.config.lib.enabled=true -Xms2g -Xmx2g -XX:+UseG1GC -XX:+PerfDisableSharedMem -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=250 -XX:+UseLargePages -XX:+AlwaysPreTouch -Dsolr.autoSoftCommit.maxTime=3000 -Dsolr.autoCommit.maxTime=60000 -Dsolr.log.muteconsole -DzkClientTimeout=15000"
        }
      ]

      secrets = [
        {
          name      = "ZK_HOST"
          valueFrom = "${aws_secretsmanager_secret.zk[0].arn}:zk_host::"
        },
        {
          name      = "DB_CREDENTIALS_SECRET_ARN"
          valueFrom = var.db_secret_arn
        }
      ]

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8983/solr/admin/ping || exit 1"
        ]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 300
      }

      ulimits = [
        {
          name      = "nofile"
          softLimit = 65000
          hardLimit = 65000
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.solr_fargate.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "solr-${count.index + 1}"
        }
      }
    }
  ])

  tags = local.tags
}

# Zookeeper task definitions with unique IDs (conditional)
resource "aws_ecs_task_definition" "zookeeper_fargate_td" {
  count                    = var.deploy_zookeeper && !var.use_external_task_definitions ? var.zookeeper_task_count : 0
  family                   = "${local.name}-zookeeper-${count.index + 1}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.zookeeper_cpu
  memory                   = var.zookeeper_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  # EFS Volume for persistent storage
  volume {
    name = "zookeeper-data"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.zookeeper_data[0].id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        access_point_id = aws_efs_access_point.zookeeper_data[0].id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = "zookeeper-container"
      image = local.zookeeper_image

      essential   = true
      stopTimeout = 120

      portMappings = [
        {
          containerPort = 2181
          hostPort      = 2181
          protocol      = "tcp"
        },
        {
          containerPort = 2888
          hostPort      = 2888
          protocol      = "tcp"
        },
        {
          containerPort = 3888
          hostPort      = 3888
          protocol      = "tcp"
        },
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      # Mount EFS volume to instance-specific subdirectory
      mountPoints = [
        {
          sourceVolume  = "zookeeper-data"
          containerPath = "/data"
          readOnly      = false
        }
      ]

      # Create required directories, set unique ID, configure ensemble, and start Zookeeper
      entryPoint = [
        "sh", "-c",
        <<-EOF
        mkdir -p /data/zk-${count.index + 1}/log && chown -R zookeeper:zookeeper /data
        
        # Create myid file with unique ID
        echo ${count.index + 1} > /data/zk-${count.index + 1}/myid
        
        # Create zoo.cfg with ensemble configuration
        cat > /conf/zoo.cfg << EOL
dataDir=/data/zk-${count.index + 1}
dataLogDir=/data/zk-${count.index + 1}/log
tickTime=3000
initLimit=20
syncLimit=10
maxClientCnxns=100
autopurge.snapRetainCount=3
autopurge.purgeInterval=24
4lw.commands.whitelist=*
clientPort=2181
clientPortAddress=0.0.0.0
standaloneEnabled=false
dynamicConfigFile=/conf/zoo.cfg.dynamic
sessionTimeout=30000
minSessionTimeout=6000
maxSessionTimeout=60000
globalOutstandingLimit=2000
preAllocSize=131072
snapCount=500000
cnxTimeout=10000
admin.enableServer=true
admin.serverPort=8080
EOL

        # Wait for DNS to be ready
        echo "Waiting for DNS resolution..."
        sleep 15
        
        # Create static ensemble configuration using individual hostnames
        cat > /conf/zoo.cfg.dynamic << EOL
server.1=${local.zk_service_name}-1.${local.private_dns_namespace}:2888:3888:participant
server.2=${local.zk_service_name}-2.${local.private_dns_namespace}:2888:3888:participant
server.3=${local.zk_service_name}-3.${local.private_dns_namespace}:2888:3888:participant
EOL
        
        echo "Starting Zookeeper with myid=${count.index + 1}"
        echo "Ensemble configuration:"
        cat /conf/zoo.cfg.dynamic
        
        exec /docker-entrypoint.sh zkServer.sh start-foreground
        EOF
      ]

      environment = [
        {
          name  = "ZOO_MY_ID"
          value = tostring(count.index + 1)
        },
        {
          name  = "ZOO_4LW_COMMANDS_WHITELIST"
          value = "*"
        },
        {
          name  = "ZOO_DATA_DIR"
          value = "/data/zk-${count.index + 1}"
        },
        {
          name  = "ZOO_DATA_LOG_DIR"
          value = "/data/zk-${count.index + 1}/log"
        },
        {
          name  = "ZOO_TICK_TIME"
          value = "3000"
        },
        {
          name  = "ZOO_INIT_LIMIT"
          value = "20"
        },
        {
          name  = "ZOO_SYNC_LIMIT"
          value = "10"
        },
        {
          name  = "ZOO_MAX_CLIENT_CNXNS"
          value = "100"
        },
        {
          name  = "ZOO_AUTOPURGE_SNAP_RETAIN_COUNT"
          value = "3"
        },
        {
          name  = "ZOO_AUTOPURGE_PURGE_INTERVAL"
          value = "24"
        },
        {
          name  = "ZOO_STANDALONE_ENABLED"
          value = "false"
        },
        {
          name  = "ZOO_SESSION_TIMEOUT"
          value = "30000"
        },
        {
          name  = "ZOO_MIN_SESSION_TIMEOUT"
          value = "6000"
        },
        {
          name  = "ZOO_MAX_SESSION_TIMEOUT"
          value = "60000"
        },
        {
          name  = "ZOO_GLOBAL_OUTSTANDING_LIMIT"
          value = "2000"
        },
        {
          name  = "ZOO_PREALLOC_SIZE"
          value = "131072"
        },
        {
          name  = "ZOO_SNAP_COUNT"
          value = "500000"
        },
        {
          name  = "JVMFLAGS"
          value = "-Xms1g -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=50 -Djute.maxbuffer=8388608"
        }
      ]

      # Health check
      healthCheck = {
        command = [
          "CMD-SHELL",
          "echo ruok | nc localhost 2181 | grep imok"
        ]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 120
      }

      # Resource limits
      ulimits = [
        {
          name      = "nofile"
          softLimit = 100000
          hardLimit = 100000
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.zookeeper_fargate[count.index].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.tags
}

# Individual Solr ECS Services
resource "aws_ecs_service" "solr_fargate_service" {
  count                  = var.solr_node_count
  name                   = "${var.project_name}-${var.environment}-solr-${count.index + 1}-service"
  cluster                = var.ecs_cluster_id
  task_definition        = var.use_external_task_definitions ? null : aws_ecs_task_definition.solr_fargate_td[count.index].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  enable_ecs_managed_tags            = true
  propagate_tags                     = "SERVICE"
  health_check_grace_period_seconds  = 600

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.solr_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.solr.arn
    container_name   = "solr-container"
    container_port   = 8983
  }

  service_registries {
    registry_arn = aws_service_discovery_service.solr_individual[count.index].arn
  }

  depends_on = [aws_lb_target_group.solr.arn]
  tags       = local.tags

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

# Individual Zookeeper ECS Services (conditional)
resource "aws_ecs_service" "zookeeper_fargate_service" {
  count                  = var.deploy_zookeeper ? var.zookeeper_task_count : 0
  name                   = "${var.project_name}-${var.environment}-zookeeper-${count.index + 1}-service"
  cluster                = var.ecs_cluster_id
  task_definition        = var.use_external_task_definitions ? null : aws_ecs_task_definition.zookeeper_fargate_td[count.index].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  enable_ecs_managed_tags            = true
  propagate_tags                     = "SERVICE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.zookeeper_service_sg[0].id]
    assign_public_ip = false
  }

  # Register with individual service for ensemble communication
  service_registries {
    registry_arn = aws_service_discovery_service.zookeeper_individual[count.index].arn
  }

  # Ensure EFS is available before starting
  depends_on = [
    aws_efs_mount_target.zookeeper_data
  ]

  tags = local.tags

  lifecycle {
    ignore_changes = [desired_count, task_definition, name]
  }
}
