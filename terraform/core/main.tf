#######
# SSM Parameters
#######
module "git_username" {
  source = "./modules/ssm"

  name        = "/credentials/git/username"
  description = "Git Username"
  value       = var.GIT_USERNAME
  type        = "SecureString"

}

module "git_authtoken" {
  source = "./modules/ssm"

  name        = "/credentials/git/auth_token"
  description = "Git Auth Token"
  value       = var.GIT_AUTH_TOKEN
  type        = "SecureString"
}

module "youtube_authtoken" {
  source = "./modules/ssm"

  name        = "/credentials/youtube/auth_token"
  description = "YouTube Auth Token"
  value       = var.YOUTUBE_AUTH_TOKEN
  type        = "SecureString"
}

module "smartproxy_username" {
  source = "./modules/ssm"

  name        = "/credentials/smartproxy/username"
  description = "SmartProxy Username"
  value       = var.PROXY_USERNAME
  type        = "SecureString"
}

module "smartproxy_password" {
  source = "./modules/ssm"

  name        = "/credentials/smartproxy/password"
  description = "SmartProxy Password"
  value       = var.PROXY_PASSWORD
  type        = "SecureString"
}

###
# SNS Topic
###
module "default_sns_topic" {
  source   = "./modules/sns"
  name     = "${var.resource_prefix}-topic"
  protocol = "email"
  endpoint = var.EMAIL_ADDRESS
}

### Log Groups
module "sfn_log_group" {
  source            = "./modules/cloudwatch"
  name              = "${var.resource_prefix}-sfn-log-group"
  retention_in_days = 14
}

###
# Core Resources
###
module "core_lambda_exec_role" {
  source = "./modules/iam"

  name = "${var.resource_prefix}-core-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
  inline_policy_enabled = true
  inline_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "sns:Publish",
          "Resource" : module.default_sns_topic.arn
        },
        {
          "Effect" : "Allow",
          "Action" : "bedrock:InvokeModel",
          "Resource" : "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
        }
      ]
    }
  )
}

module "core_lambda_func" {
  source        = "./modules/lambda"
  function_name = "${var.resource_prefix}-lambda"
  role_arn      = module.core_lambda_exec_role.arn
  image_uri     = data.aws_ecr_image.core_image_lookup.image_uri
  timeout       = 900
  environment_variables = {
    SNS_TOPIC_ARN        = module.default_sns_topic.arn
    REPOSITORY_URL       = var.BLOG_GIT_REPO_URL
    YOUTUBE_CHANNEL_NAME = var.YOUTUBE_CHANNEL_NAME
  }
  create_event_invoke_config          = true
  event_invoke_maximum_retry_attempts = 0
  event_invoke_qualifier              = "$LATEST"
}

module "sfn_iam_role" {
  source = "./modules/iam"

  name = "${var.resource_prefix}-sfn-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })
  inline_policy_enabled = true

  inline_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "sns:Publish",
          "Resource" : module.default_sns_topic.arn
        },
        {
          "Effect" : "Allow",
          "Action" : "lambda:InvokeFunction",
          "Resource" : module.core_lambda_func.arn
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogDelivery",
            "logs:CreateLogStream",
            "logs:GetLogDelivery",
            "logs:UpdateLogDelivery",
            "logs:DeleteLogDelivery",
            "logs:ListLogDeliveries",
            "logs:PutLogEvents",
            "logs:PutResourcePolicy",
            "logs:DescribeResourcePolicies",
            "logs:DescribeLogGroups"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_sfn_state_machine" "default" {
  name     = "${var.resource_prefix}-sfn"
  role_arn = module.sfn_iam_role.arn
  definition = jsonencode(
    jsondecode(
      replace(
        replace(
          file("${path.module}/sfn_definition/definition.json"),
          "CORE_LAMBDA_ARN",
          module.core_lambda_func.arn
        ),
        "DES_LAMBDA_URL",
        module.des_lambda_func.function_url
      )
    )
  )
  logging_configuration {
    log_destination        = "${module.sfn_log_group.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

module "ecs_log_group" {
  source            = "./modules/cloudwatch"
  name              = "${var.resource_prefix}-ecs-log-group"
  retention_in_days = 14
}
module "vdl_cluster_exec_role" {
  source = "./modules/iam"

  name = "${var.resource_prefix}-ecstasksdef-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
  inline_policy_enabled = true

  inline_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "states:StartExecution",
          "Resource" : aws_sfn_state_machine.default.arn
        },
      ]
    }
  )
}
module "vdl_ecs_cluster" {
  source = "./modules/ecs"

  health_check_path = "/"
  log_group_name    = module.ecs_log_group.name
  ecs_cluster_name  = "${var.resource_prefix}-cluster"

  task_family        = "${var.resource_prefix}-vdl-taskfamily"
  execution_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole" # SVC Execution Role
  task_role_arn      = module.vdl_cluster_exec_role.arn

  container_name  = "video-drop-listener"
  container_image = data.aws_ecr_image.vdl_image_lookup.image_uri
  container_port  = 80

  service_name = "${var.resource_prefix}-vdl-service"
  region       = var.region

  task_definition_env_variables = [
    {
      name  = "STEP_FUNCTION_ARN"
      value = aws_sfn_state_machine.default.arn
    }
  ]
}

module "waf" {
  source                 = "./modules/waf"
  acl_name               = "dsb-block-crawlers-acl"
  acl_description        = "Web ACL to block common web crawlers"
  acl_metric_name        = "dsb-block-crawlers-acl"
  scope                  = "REGIONAL"
  rule_group_name        = "block-crawlers-rule-group"
  rule_group_metric_name = "block-crawlers-rule-group"
  rule_group_capacity    = 50
  resource_arn           = module.vdl_ecs_cluster.load_balancer_id

  rules = [
    {
      name     = "block-googlebot"
      priority = 1
      statement = {
        byte_match_statement = {
          search_string = "Googlebot"
          field_to_match = {
            single_header = {
              name = "user-agent"
            }
          }
          positional_constraint = "CONTAINS"
          text_transformation = [
            {
              priority = 0
              type     = "LOWERCASE"
            }
          ]
        }
      }
      metric_name = "block-googlebot"
    },
    {
      name     = "block-bingbot"
      priority = 2
      statement = {
        byte_match_statement = {
          search_string = "bingbot"
          field_to_match = {
            single_header = {
              name = "user-agent"
            }
          }
          positional_constraint = "CONTAINS"
          text_transformation = [
            {
              priority = 0
              type     = "LOWERCASE"
            }
          ]
        }
      }
      metric_name = "block-bingbot"
    },
    {
      name     = "rate-limit"
      priority = 3
      statement = {
        rate_based_statement = {
          limit              = 100
          aggregate_key_type = "IP"
          scope_down_statement = {
            byte_match_statement = {
              search_string = "HTTP"
              field_to_match = {
                method = {}
              }
              positional_constraint = "STARTS_WITH"
              text_transformation = [
                {
                  priority = 0
                  type     = "NONE"
                }
              ]
            }
          }
        }
      }
      metric_name = "rate-limit"
    }
  ]
}


###
# Decision Email Sender (DES)
###
module "des_lambda_exec_role" {
  source = "./modules/iam"

  name = "${var.resource_prefix}-des-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
  inline_policy_enabled = true

  inline_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "sns:Publish",
          "Resource" : module.default_sns_topic.arn
        },
        {
          "Effect" : "Allow",
          "Action" : "states:SendTaskSuccess",
          "Resource" : aws_sfn_state_machine.default.arn
        },
      ]
    }
  )
}

module "des_lambda_func" {
  source        = "./modules/lambda"
  function_name = "${var.resource_prefix}-des"

  role_arn  = module.des_lambda_exec_role.arn
  image_uri = data.aws_ecr_image.des_image_lookup.image_uri
  timeout   = 120 # 2 minutes

  create_function_url               = true
  create_permission                 = true
  permission_action                 = "lambda:InvokeFunctionUrl"
  permission_principal              = "*"
  permission_function_url_auth_type = "NONE"
  function_url_authorization_type   = "NONE"

  environment_variables = {
    SNS_TOPIC_ARN = module.default_sns_topic.arn
  }
}

###
# Subscriber
###
module "subscriber_lambda_exec_role" {
  source = "./modules/iam"

  name = "${var.resource_prefix}-sub-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns   = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  inline_policy_enabled = true
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ec2:DescribeNetworkInterfaces"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
module "subscriber_lambda_func" {
  source = "./modules/lambda"

  function_name = "${var.resource_prefix}-subscriber"
  role_arn      = module.subscriber_lambda_exec_role.arn
  image_uri     = data.aws_ecr_image.subscriber_image_lookup.image_uri
  timeout       = 120 # 2 minutes
  environment_variables = {
    CLUSTER_NAME      = module.vdl_ecs_cluster.name
    CALLBACK_TASK_ARN = module.vdl_ecs_cluster.task_definition_arn
    TOPIC_URL         = var.YOUTUBE_TOPIC_URL
  }

  create_event_rule              = true
  event_rule_name                = "${var.resource_prefix}-sub-lambda-event-rule"
  event_target_id                = "${var.resource_prefix}-sub-lambda-event-target"
  event_rule_description         = "Triggers Lambda function subscriber every day!"
  event_rule_schedule_expression = "rate(1 day)"

  create_permission    = true
  permission_action    = "lambda:InvokeFunction"
  permission_principal = "events.amazonaws.com"
}
