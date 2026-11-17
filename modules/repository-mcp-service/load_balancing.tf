resource "aws_lb_target_group" "mcp" {
  name                 = substr("${local.name_prefix}-tg", 0, 32)
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    path                = "/health/ready"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = local.tags
}

resource "aws_lb_listener_certificate" "mcp" {
  count = var.public_alb_certificate_arn != null ? 1 : 0

  listener_arn    = var.public_alb_https_listener_arn
  certificate_arn = var.public_alb_certificate_arn
}

resource "aws_lb_listener_rule" "mcp" {
  listener_arn = var.public_alb_https_listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mcp.arn
  }

  condition {
    host_header {
      values = [lower(var.public_hostname)]
    }
  }

  tags = local.tags
}
