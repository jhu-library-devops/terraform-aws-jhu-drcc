# Application Load Balancer and related resources
resource "aws_s3_bucket" "alb_logs" {
  count  = var.enable_enhanced_monitoring ? 1 : 0
  bucket = "${local.name}-alb-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"
  tags   = local.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  count  = var.enable_enhanced_monitoring ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {
      prefix = local.alb_log_prefix
    }
    expiration {
      days = 90
    }
  }
}

data "aws_iam_policy_document" "alb_logs" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.alb_logs[0].arn}/${local.alb_log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "${aws_s3_bucket.alb_logs[0].arn}/private-${local.alb_log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.alb_logs[0].arn]
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.enable_enhanced_monitoring ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id
  policy = data.aws_iam_policy_document.alb_logs[0].json
}

# Public Application Load Balancer (internet-facing)
resource "aws_lb" "main" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = local.public_subnet_ids
  tags               = local.tags

  dynamic "access_logs" {
    for_each = var.enable_enhanced_monitoring ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logs[0].id
      prefix  = local.alb_log_prefix
      enabled = true
    }
  }

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# Private Application Load Balancer (internal)
resource "aws_lb" "private" {
  name               = "private-${local.name}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private_alb_sg.id]
  subnets            = local.private_subnet_ids
  tags               = local.tags
}

# Public ALB Listeners
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = var.ssl_certificate_arn

  # Default action - return 404 (application modules will add rules)
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = local.tags
}

# Private ALB Listeners
resource "aws_lb_listener" "private_http" {
  load_balancer_arn = aws_lb.private.id
  port              = "80"
  protocol          = "HTTP"

  # Default action - return 404 (application modules will add rules)
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = local.tags
}

resource "aws_lb_listener" "private_solr" {
  load_balancer_arn = aws_lb.private.id
  port              = "8983"
  protocol          = "HTTP"

  # Default action - return 404 (Solr module will add rules)
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = local.tags
}

resource "aws_route53_zone" "private_dspace_zone" {
  name = "${var.environment}.internal.dspace"
  vpc {
    vpc_id = local.vpc_id
  }
}

resource "aws_route53_record" "private_dspace_zone_alb_alias" {
  zone_id = aws_route53_zone.private_dspace_zone.zone_id
  name    = "${var.environment}.internal.dspace"
  type    = "A"

  alias {
    name                   = aws_lb.private.dns_name
    zone_id                = aws_lb.private.zone_id
    evaluate_target_health = true
  }
}
