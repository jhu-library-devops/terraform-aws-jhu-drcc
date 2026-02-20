# RDS Database resources
resource "aws_db_subnet_group" "main" {
  count      = var.deploy_database ? 1 : 0
  name       = "${local.name}-sng"
  subnet_ids = local.private_subnet_ids

  tags = merge(local.tags, { Name = "${local.name}-db-subnet-group" })
}

resource "random_password" "db" {
  count = var.deploy_database ? 1 : 0

  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "db" {
  count = var.deploy_database ? 1 : 0
  name  = "${local.name}/${var.environment}/rds-credentials"

  tags = merge(local.tags, {
    "aws:secretsmanager:rotation" = var.db_secret_rotation_type
  })
}

resource "aws_secretsmanager_secret_version" "db" {
  count     = var.deploy_database ? 1 : 0
  secret_id = aws_secretsmanager_secret.db[0].id
  secret_string = jsonencode({
    username             = var.db_username
    password             = random_password.db[0].result
    engine               = "postgres"
    host                 = aws_db_instance.main[0].address
    port                 = aws_db_instance.main[0].port
    dbname               = var.db_name
    dbInstanceIdentifier = aws_db_instance.main[0].id
  })
  lifecycle { ignore_changes = [secret_string] }
}

resource "aws_db_instance" "main" {
  count = var.deploy_database ? 1 : 0

  identifier             = "${local.name}-db"
  allocated_storage      = var.db_allocated_storage
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db[0].result
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  publicly_accessible    = false

  multi_az                  = var.db_multi_az
  backup_retention_period   = var.db_backup_retention_period
  deletion_protection       = var.db_deletion_protection
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${local.name}-db-final-snapshot"

  tags = merge(local.tags, { Name = "${local.name}-db" })

  lifecycle {
    ignore_changes = [password]
  }
}
