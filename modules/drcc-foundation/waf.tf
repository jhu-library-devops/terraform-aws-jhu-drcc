# WAF Web ACL for Application Load Balancer protection
resource "aws_wafv2_web_acl" "main" {
  name  = "${local.name}-waf"
  scope = "REGIONAL"
  tags  = local.tags

  default_action {
    allow {}
  }

  # Custom rule looking for requests from an IP Set of trusted IPs
  rule {
    name     = "dspace-${var.environment}-trusted-ips-rule"
    priority = 0

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = var.trusted_ip_set_arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "dspace-${var.environment}-trusted-ips-rule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {
            }
          }
        }

        rule_action_override {
          name = "CrossSiteScripting_BODY"
          action_to_use {
            count {
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - IP Reputation List
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Bot Control Rule Set
  rule {
    name     = "AWS-AWSManagedRulesBotControlRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SignalNonBrowserUserAgent"
          action_to_use {
            count {
            }
          }
        }

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            enable_machine_learning = false
            inspection_level        = "COMMON"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - user_agent_match_rule overrides user agent rule in Bot Control Rule Set
  rule {
    name     = "user_agent_match_rule"
    priority = 4

    action {
      block {}
    }

    statement {
      and_statement {

        statement {
          label_match_statement {
            key   = "awswaf:managed:aws:bot-control:signal:non_browser_user_agent"
            scope = "LABEL"
          }
        }

        statement {
          not_statement {
            statement {
              byte_match_statement {
                positional_constraint = "EXACTLY"
                search_string         = "Vireo Sword 1.0 Depositor"

                field_to_match {
                  single_header {
                    name = "user-agent"
                  }
                }

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "user_agent_match_rule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "match_rule_verified_bots"
    priority = 5

    action {
      dynamic "block" {
        for_each = var.waf_verified_bots_action == "block" ? ["block"] : []
        content {}
      }
      dynamic "allow" {
        for_each = var.waf_verified_bots_action == "allow" ? ["allow"] : []
        content {}
      }
    }

    statement {
      label_match_statement {
        key   = "awswaf:managed:aws:bot-control:bot:verified"
        scope = "LABEL"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "match_rule_verified_bots"
      sampled_requests_enabled   = true
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-waf"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with the public Application Load Balancer
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
