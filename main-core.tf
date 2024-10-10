locals {
  sfn_name        = "dsb-blogging-assistant-sfn"
  default_sfn_arn = "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${local.sfn_name}"
}
# SNS Topic
resource "aws_sns_topic" "default" {
  name = "dsb-blogging-assistant-yt-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.default.arn
  protocol  = "email"
  endpoint  = "damien@thedevsecblueprint.com"
}

# ECR Repository
data "aws_ecr_image" "core_lambda_image_lookup" {
  repository_name = aws_ecr_repository.core_lambda_image.name
  most_recent     = true
}

resource "aws_ecr_repository" "core_lambda_image" {
  name         = "dsb-blogging-assistant-core-lambda-image"
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "core_lambda_image_lifecycle_policy" {
  repository = aws_ecr_repository.core_lambda_image.name

  # https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy_examples.html
  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep only one untagged image, expire all others",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
  EOF
}


# Lambda Function
data "aws_iam_policy_document" "core_lambda_exec_role_inline_policy" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.default.arn]
  }

  statement {
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
    ]
  }
}
resource "aws_iam_role" "core_lambda_exec_role" {
  name = "dsb-ba-core-lambda-exec-role"
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

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"]
  inline_policy {
    name   = "InlinePolicy"
    policy = data.aws_iam_policy_document.core_lambda_exec_role_inline_policy.json
  }
}

resource "aws_lambda_function" "core_lambda_func" {
  function_name = "dsb-blogging-assistant-lambda"
  role          = aws_iam_role.core_lambda_exec_role.arn

  image_uri    = data.aws_ecr_image.core_lambda_image_lookup.image_uri
  timeout      = 900 # 15 minutes
  package_type = "Image"

  environment {
    variables = {
      SNS_TOPIC_ARN        = aws_sns_topic.default.arn
      REPOSITORY_URL       = "https://github.com/The-DevSec-Blueprint/dsb-digest"
      YOUTUBE_CHANNEL_NAME = "Damien Burks | The DevSec Blueprint (DSB)"
    }
  }
  depends_on = [aws_ecr_repository.core_lambda_image]
}

resource "aws_lambda_function_event_invoke_config" "core_inv_event_conf" {
  function_name          = aws_lambda_function.core_lambda_func.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"
}

# Step Function
resource "aws_sfn_state_machine" "default_sfn" {
  name       = "dsb-blogging-assistant-sfn"
  role_arn   = aws_iam_role.sfn_iam_role.arn
  definition = <<EOF
  {
  "StartAt": "Get Video Information",
  "States": {
    "Get Video Information": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.core_lambda_func.arn}",
      "Parameters": {
        "actionName": "getVideoId",
        "videoName.$": "$.videoName",
        "videoUrl.$": "$.videoUrl"
      },
      "ResultPath": "$.getVideoId",
      "Next": "Is Video Short?"
    },
    "Is Video Short?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.getVideoId.isShort",
          "BooleanEquals": true,
          "Next": "Ignore Short Video"
        },
        {
          "Variable": "$.getVideoId.isShort",
          "BooleanEquals": false,
          "Next": "Send Video Confirmation Email"
        }
      ],
      "Default": "Send Video Confirmation Email"
    },
    "Ignore Short Video": {
      "Type": "Pass",
      "End": true
    },
    "Send Video Confirmation Email": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.core_lambda_func.arn}",
        "Payload": {
          "actionName": "sendConfirmationEmail",
          "videoName.$": "$.videoName",
          "token.$":"$$.Task.Token",
          "ExecutionContext.$": "$$",
          "processorLambdaFunctionUrl":"${aws_lambda_function_url.dcm_processor_lambda_url.function_url}"
        }
      },
      "TimeoutSeconds": 300,
      "ResultPath": "$.sendConfirmationEmail",
      "Next": "Is The Video Technical?"
    },
    "Is The Video Technical?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.sendConfirmationEmail.Status",
          "StringEquals": "Video is confirmed as technical!",
          "Next": "Generate Technical Blog Post with OpenAI"
        }
      ],
      "Default": "Generate Non-Technical Blog Post with OpenAI"
    },
    "Generate Technical Blog Post with Claude": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.core_lambda_func.arn}",
      "Parameters": {
        "actionName": "generateBlogPost",
        "videoName.$": "$.videoName",
        "videoType": "technical",
        "videoId.$": "$.getVideoId.videoId"
      },
      "ResultPath": "$.generateBlogPost",
      "Next": "Publish MD Blog to GitHub"
    },
    "Generate Non-Technical Blog Post with Claude": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.core_lambda_func.arn}",
      "Parameters": {
        "actionName": "generateBlogPost",
        "videoName.$": "$.videoName",
        "videoType": "non-technical",
        "videoId.$": "$.getVideoId.videoId"
      },
      "ResultPath": "$.generateBlogPost",
      "Next": "Publish MD Blog to GitHub"
    },
    "Publish MD Blog to GitHub": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.core_lambda_func.arn}",
      "Parameters": {
        "actionName": "commitBlogToGitHub",
        "videoName.$": "$.videoName",
        "blogPostContents.$": "$.generateBlogPost.blogPostContents"
      },
      "ResultPath": "$.commitBlogToGitHub",
      "Next": "Send Email To DSB"
    },
    "Send Email To DSB": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.core_lambda_func.arn}",
      "Parameters": {
        "actionName": "sendEmail",
        "commitId.$": "$.commitBlogToGitHub.commitId",
        "branchName.$": "$.commitBlogToGitHub.branchName",
        "videoName.$": "$.videoName"
      },
      "ResultPath": "$.sendEmail",
      "End": true
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
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name   = "DefaultInlinePolicy"
    policy = data.aws_iam_policy_document.sfn_inline_policy.json
  }
}

data "aws_iam_policy_document" "sfn_inline_policy" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.core_lambda_func.arn]
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
