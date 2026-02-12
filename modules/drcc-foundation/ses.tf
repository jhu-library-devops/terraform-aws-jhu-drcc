# SES configuration
resource "aws_ses_domain_identity" "app_email_domain" {
  domain = var.app_email_domain
}