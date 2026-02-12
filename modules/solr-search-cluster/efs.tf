# EFS for Zookeeper persistent storage
resource "aws_efs_file_system" "zookeeper_data" {
  count = var.deploy_zookeeper ? 1 : 0

  creation_token = "${local.name}-zookeeper-data"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.tags, {
    Name = "${local.name}-zookeeper-data"
  })
}

# EFS for Solr data persistence
resource "aws_efs_file_system" "solr_data" {
  creation_token = "${local.name}-solr-data"

  performance_mode = "maxIO"
  throughput_mode  = "bursting"

  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.tags, {
    Name = "${local.name}-solr-data"
  })
}

# EFS Mount Targets for Zookeeper (one per AZ)
resource "aws_efs_mount_target" "zookeeper_data" {
  count = var.deploy_zookeeper ? length(var.private_subnet_ids) : 0

  file_system_id  = aws_efs_file_system.zookeeper_data[0].id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.zookeeper_efs[0].id]
}

# EFS Mount Targets for Solr data (one per AZ)
resource "aws_efs_mount_target" "solr_data" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.solr_data.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.solr_efs.id]
}

# Security group for Zookeeper EFS access
resource "aws_security_group" "zookeeper_efs" {
  count = var.deploy_zookeeper ? 1 : 0

  name_prefix = "${local.name}-zookeeper-efs-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.zookeeper_service_sg[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-zookeeper-efs-sg"
  })
}

# Security group for Solr EFS access
resource "aws_security_group" "solr_efs" {
  name_prefix = "${local.name}-solr-efs-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.solr_service_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-solr-efs-sg"
  })
}

# EFS Access Point for Zookeeper
resource "aws_efs_access_point" "zookeeper_data" {
  count = var.deploy_zookeeper ? 1 : 0

  file_system_id = aws_efs_file_system.zookeeper_data[0].id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/zookeeper"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name}-zookeeper-access-point"
  })
}

# EFS Access Point for Solr data
resource "aws_efs_access_point" "solr_data" {
  file_system_id = aws_efs_file_system.solr_data.id

  posix_user {
    uid = 8983 # Solr user ID
    gid = 8983 # Solr group ID
  }

  root_directory {
    path = "/solr-data"
    creation_info {
      owner_uid   = 8983
      owner_gid   = 8983
      permissions = "755"
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name}-solr-data-access-point"
  })
}

# Individual EFS Access Points for each Solr node
resource "aws_efs_access_point" "solr_node" {
  count = var.solr_node_count

  file_system_id = aws_efs_file_system.solr_data.id

  posix_user {
    uid = 8983
    gid = 8983
  }

  root_directory {
    path = "/solr-data/solr-${count.index + 1}"
    creation_info {
      owner_uid   = 8983
      owner_gid   = 8983
      permissions = "755"
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name}-solr-${count.index + 1}-access-point"
  })
}
