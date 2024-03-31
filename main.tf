# SNS Topic
resource "aws_sns_topic" "default" {
  name = "dsb-blogging-assistant-yt-topic"
}

# SSM Parameters
resource "aws_ssm_parameter" "openai_authtoken" {
  name  = "credentials/openai/auth_token"
  type  = "SecureString"
  value = var.OPENAI_AUTH_TOKEN
}

resource "aws_ssm_parameter" "git_username" {
  name  = "credentials/git/username"
  type  = "String"
  value = var.GIT_USERNAME
}

resource "aws_ssm_parameter" "git_authtoken" {
  name  = "credentials/git/auth_token"
  type  = "SecureString"
  value = var.GIT_AUTH_TOKEN
}

resource "aws_ssm_parameter" "youtube_authtoken" {
  name  = "credentials/youtube/auth_token"
  type  = "SecureString"
  value = var.YOUTUBE_AUTH_TOKEN
}

# Lambda Function
resource "aws_iam_role" "lambda_exec_role" {
  name = "dsb-blogging-assistant-lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "archive_file" "lambda_src" {
  type        = "zip"
  source_dir  = "./lambda"
  output_path = "lambda_src.zip"
}

resource "aws_lambda_function" "default" {
  filename         = "lambda_src.zip"
  function_name    = "dsb-blogging-assistant-lambda"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "src.handler.main"
  source_code_hash = data.archive_file.lambda_src.output_base64sha256
  runtime          = "python3.11"

  timeout = 120 # 2 minutes
  environment {
    variables = {
      "CHANNEL_NAME" : "The DevSec Blueprint (DSB)"
    }
  }
}

# Step Function
resource "aws_sfn_state_machine" "default_sfn" {
  name       = "dsb-blogging-assistant-sfn"
  role_arn   = aws_iam_role.sfn_iam_role.arn
  definition = <<EOF
  {
    "StartAt": "getVideoId",
    "States": {
      "getVideoId": {
        "Type": "Task",
        "Resource": "${aws_lambda_function.default.arn}",
        "Parameters": {
          "input": {
            "action_name": "getVideoId",
            "videoName.$": "$.videoName"
          }
        },
        "ResultPath": "$.getVideoId",
        "Next": "Success"
      },
      "Success": {
        "Type": "Succeed"
      }
    }
  }
  EOF
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.default_sfn_lg.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

resource "aws_cloudwatch_log_group" "default_sfn_lg" {
  name = "dsb-blogging-assistant-sfn-log-group"
}

resource "aws_iam_role" "sfn_iam_role" {
  name = "dsb-blogging-assistant-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name   = "DefaultInlinePolicy"
    policy = data.aws_iam_policy_document.inline_policy.json
  }
}

data "aws_iam_policy_document" "inline_policy" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.default.arn]
  }

  statement {
    actions = [
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
    ]
    resources = ["*"]
  }
}