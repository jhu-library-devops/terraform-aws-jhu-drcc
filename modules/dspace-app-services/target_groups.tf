# DSpace Application Target Groups

# UI Target Group
resource "aws_lb_target_group" "ui" {
  name                 = "${var.organization}-${var.environment}-${var.project_name}-ui-tg"
  port                 = 4000
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

# Public API Target Group
resource "aws_lb_target_group" "public_api" {
  name                 = "${var.organization}-${var.environment}-${var.project_name}-api-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 15

  health_check {
    path                = "/server/api"
    matcher             = "200-499"
    interval            = 35
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  tags = local.tags
}

# Private API Target Group
resource "aws_lb_target_group" "private_api" {
  name                 = "private-${var.organization}-${var.environment}-${var.project_name}-api-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 15

  health_check {
    path                = "/server/api"
    matcher             = "200-499"
    interval            = 35
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  tags = local.tags
}

# Listener Rules - Attach target groups to ALB listeners

# Public HTTPS Listener - Default action forwards to UI
resource "aws_lb_listener_rule" "ui_default" {
  listener_arn = var.alb_https_listener_arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# Public HTTPS Listener - API rule
resource "aws_lb_listener_rule" "public_api" {
  listener_arn = var.alb_https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_api.arn
  }

  condition {
    path_pattern {
      values = ["/server/*"]
    }
  }
}

# Private ALB Listener - API rule
resource "aws_lb_listener_rule" "private_api" {
  listener_arn = var.private_alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_api.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
