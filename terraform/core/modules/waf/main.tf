resource "aws_wafv2_web_acl" "this" {
  name        = var.acl_name
  description = var.acl_description
  scope       = var.scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.acl_metric_name
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_rule_group" "this" {
  name     = var.rule_group_name
  scope    = var.scope
  capacity = var.rule_group_capacity

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.rule_group_metric_name
    sampled_requests_enabled   = true
  }

  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        block {}
      }

      statement {
        dynamic "byte_match_statement" {
          for_each = contains(keys(rule.value.statement), "byte_match_statement") ? [rule.value.statement.byte_match_statement] : []
          content {
            search_string         = byte_match_statement.value.search_string
            positional_constraint = byte_match_statement.value.positional_constraint

            field_to_match {
              dynamic "single_header" {
                for_each = contains(keys(byte_match_statement.value.field_to_match), "single_header") ? [byte_match_statement.value.field_to_match.single_header] : []
                content {
                  name = single_header.value.name
                }
              }

              dynamic "method" {
                for_each = contains(keys(byte_match_statement.value.field_to_match), "method") ? [byte_match_statement.value.field_to_match.method] : []
                content {}
              }
            }

            dynamic "text_transformation" {
              for_each = byte_match_statement.value.text_transformation
              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }

        dynamic "rate_based_statement" {
          for_each = contains(keys(rule.value.statement), "rate_based_statement") ? [rule.value.statement.rate_based_statement] : []
          content {
            limit              = rate_based_statement.value.limit
            aggregate_key_type = rate_based_statement.value.aggregate_key_type

            scope_down_statement {
              byte_match_statement {
                search_string         = rate_based_statement.value.scope_down_statement.byte_match_statement.search_string
                positional_constraint = rate_based_statement.value.scope_down_statement.byte_match_statement.positional_constraint

                field_to_match {
                  method {}
                }

                dynamic "text_transformation" {
                  for_each = rate_based_statement.value.scope_down_statement.byte_match_statement.text_transformation
                  content {
                    priority = text_transformation.value.priority
                    type     = text_transformation.value.type
                  }
                }
              }
            }
          }
        }

      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = true
      }
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = var.resource_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
