# Optional ACM Certificate for HTTPS
# When create_ssl_certificate is true, this module creates and manages the SSL certificate.
# When false, an existing certificate ARN must be provided via ssl_certificate_arn.

resource "aws_acm_certificate" "main" {
  count             = var.create_ssl_certificate ? 1 : 0
  domain_name       = var.public_domain
  validation_method = "DNS"

  tags = merge(local.tags, {
    Name = "${local.name}-certificate"
  })

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.public_domain != null && var.public_domain != ""
      error_message = "Variable 'public_domain' must be set to a non-empty value when 'create_ssl_certificate' is true."
    }
  }
}

locals {
  ssl_certificate_arn = var.create_ssl_certificate ? aws_acm_certificate.main[0].arn : var.ssl_certificate_arn
}
