# Preserve managed RDS identities for users upgrading from the historical
# foundation-owned database layout. Consumers with different module names must
# perform equivalent state moves in their root module before applying.

moved {
  from = module.foundation.aws_db_subnet_group.main[0]
  to   = module.dspace_app.aws_db_subnet_group.main[0]
}

moved {
  from = module.foundation.random_password.db[0]
  to   = module.dspace_app.random_password.db[0]
}

moved {
  from = module.foundation.aws_secretsmanager_secret.db[0]
  to   = module.dspace_app.aws_secretsmanager_secret.db[0]
}

moved {
  from = module.foundation.aws_secretsmanager_secret_version.db[0]
  to   = module.dspace_app.aws_secretsmanager_secret_version.db[0]
}

moved {
  from = module.foundation.aws_db_instance.main[0]
  to   = module.dspace_app.aws_db_instance.main[0]
}

moved {
  from = module.foundation.aws_security_group.rds[0]
  to   = module.dspace_app.aws_security_group.rds[0]
}

moved {
  from = module.foundation.aws_vpc_security_group_ingress_rule.db_ingress_rule[0]
  to   = module.dspace_app.aws_vpc_security_group_ingress_rule.db_ingress_rule[0]
}
