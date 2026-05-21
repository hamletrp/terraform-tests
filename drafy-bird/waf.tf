  # waf.tf
resource "aws_wafv2_web_acl" "drafty_bird" {
    provider    = aws.us_east_1          # CloudFront WAF must be us-east-1
    name        = "drafty-bird"
    scope       = "CLOUDFRONT"
    description = "WAF for drafty-bird CloudFront distribution"

    default_action {
      allow {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "drafty-bird-waf"
      sampled_requests_enabled   = true
    }


    rule {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
      override_action { 
        none {} 
      }
      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = "AWSManagedRulesCommonRuleSet"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "CommonRuleSet"
        sampled_requests_enabled   = true
      }
    }

    rule {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 20
      override_action { 
        none {} 
      }
      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = "AWSManagedRulesSQLiRuleSet"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "SQLiRuleSet"
        sampled_requests_enabled   = true
      }
    }

    rule {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 30
      override_action { 
        none {} 
      }
      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "KnownBadInputs"
        sampled_requests_enabled   = true
      }
    }

    rule {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = 40
      override_action { 
        none {} 
      }
      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = "AWSManagedRulesAmazonIpReputationList"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "IpReputationList"
        sampled_requests_enabled   = true
      }
    }

    rule {
      name     = "RateLimitPerIP"
      priority = 50
      action { 
        block {} 
      }
      statement {
        rate_based_statement {
          limit              = 2000   # requests per 5-minute window
          aggregate_key_type = "IP"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimitPerIP"
        sampled_requests_enabled   = true
      }
    }
}