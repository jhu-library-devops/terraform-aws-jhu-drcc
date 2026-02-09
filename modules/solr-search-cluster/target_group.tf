# Solr Target Group
resource "aws_lb_target_group" "solr" {
  name                 = "${local.name}-solr-tg"
  port                 = 8983
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 15

  health_check {
    path                = "/"
    matcher             = "200-499"
    interval            = 35
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  tags = local.tags
}

# Attach Solr target group to private ALB listener
resource "aws_lb_listener_rule" "solr" {
  listener_arn = var.private_solr_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.solr.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
