# SNS Topic
resource "aws_sns_topic" "default" {
  name = "dsb-blogging-assistant-yt-topic"
}

# SSM Parameters
resource "aws_ssm_parameter" "openai_authtoken" {
  name  = "/credentials/openai/auth_token"
  type  = "SecureString"
  value = var.OPENAI_AUTH_TOKEN
}

resource "aws_ssm_parameter" "git_username" {
  name  = "/credentials/git/username"
  type  = "String"
  value = var.GIT_USERNAME
}

resource "aws_ssm_parameter" "git_authtoken" {
  name  = "/credentials/git/auth_token"
  type  = "SecureString"
  value = var.GIT_AUTH_TOKEN
}

resource "aws_ssm_parameter" "youtube_authtoken" {
  name  = "/credentials/youtube/auth_token"
  type  = "SecureString"
  value = var.YOUTUBE_AUTH_TOKEN
}

# ECR Repository
resource "aws_ecr_repository" "lambda_image" {
  name         = "dsb-blogging-assistant-lambda-image"
  force_delete = true
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

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"]
  inline_policy {
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_lambda_function" "default" {
  function_name = "dsb-blogging-assistant-lambda"
  role          = aws_iam_role.lambda_exec_role.arn

  image_uri    = "${aws_ecr_repository.lambda_image.repository_url}:latest"
  timeout      = 120 # 2 minutes
  package_type = "Image"

  depends_on = [aws_ecr_repository.lambda_image]
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
          "actionName": "getVideoId",
          "videoName.$": "$.videoName"
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