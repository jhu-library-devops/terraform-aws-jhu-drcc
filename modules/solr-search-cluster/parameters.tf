# SSM Parameter Store
resource "aws_ssm_parameter" "db_url" {
  name  = "/dspace/${var.environment}/db-url"
  type  = "String"
  value = "jdbc:postgresql://${var.db_endpoint}/dspace"
}

resource "aws_ssm_parameter" "server-ssr-url" {
  name  = "/dspace/${var.environment}/server-ssr-url"
  type  = "String"
  value = "http://${var.environment}.internal.dspace/server"
}

resource "aws_ssm_parameter" "server-url" {
  name  = "/dspace/${var.environment}/server-url"
  type  = "String"
  value = "https://${var.public_domain}/server"
}

resource "aws_ssm_parameter" "solr-url" {
  name  = "/dspace/${var.environment}/solr-url"
  type  = "String"
  value = "http://${var.environment}.internal.dspace:8983/solr"
}

resource "aws_ssm_parameter" "ui-url" {
  name  = "/dspace/${var.environment}/ui-url"
  type  = "String"
  value = "https://${var.public_domain}"
}