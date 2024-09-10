resource "aws_wafv2_web_acl" "ecs_waf_acl" {
  name        = "dsb-block-crawlers-acl"
  description = "Web ACL to block common web crawlers"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "dsb-block-crawlers-acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_rule_group" "block_crawlers" {
  name     = "block-crawlers-rule-group"
  scope    = "REGIONAL"
  capacity = 50

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "block-crawlers-rule-group"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "block-googlebot"
    priority = 1
    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string = "Googlebot"
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }
        positional_constraint = "CONTAINS"

        # Required text_transformation block
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-googlebot"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "block-bingbot"
    priority = 2
    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string = "bingbot"
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }
        positional_constraint = "CONTAINS"

        # Required text_transformation block
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-bingbot"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit"
    priority = 3
    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100 # Block if more than 50 requests are made within 5 minutes
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            search_string = "HTTP"
            field_to_match {
              method {}
            }
            positional_constraint = "STARTS_WITH"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }
}


resource "aws_wafv2_web_acl_association" "default_waf" {
  resource_arn = aws_alb.application_load_balancer.id
  web_acl_arn  = aws_wafv2_web_acl.ecs_waf_acl.arn
}
