# Secrets management for Zookeeper
resource "aws_secretsmanager_secret" "zk" {
  count = var.deploy_zookeeper ? 1 : 0
  name  = "${local.name}/${var.environment}/zookeeper-host"
  tags  = local.tags
}

resource "aws_secretsmanager_secret_version" "zk" {
  count     = var.deploy_zookeeper ? 1 : 0
  secret_id = aws_secretsmanager_secret.zk[0].id
  secret_string = jsonencode({
    zk_host = local.zk_connection_string
  })
}
