# Security group for ECS tasks on JHUnet
# No inbound rules — batch/ETL workloads initiate outbound connections only
resource "aws_security_group" "ecs_tasks" {
  name        = local.ecs_sg_name
  description = local.ecs_sg_description
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = local.ecs_sg_name })
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress" {
  for_each          = toset(var.egress_cidr_blocks)
  security_group_id = aws_security_group.ecs_tasks.id

  ip_protocol = "-1"
  cidr_ipv4   = each.key
}
