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
data "aws_ecr_image" "lambda_image_lookup" {
  repository_name = aws_ecr_repository.lambda_image.name
  most_recent     = true
}

resource "aws_ecr_repository" "lambda_image" {
  name         = "dsb-blogging-assistant-lambda-image"
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "lambda_image_lifecycle_policy" {
  repository = aws_ecr_repository.lambda_image.name

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
    name = "dsb-blogging-assistant-lambda-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "sns:Publish",
          ]
          Effect   = "Allow"
          Resource = "${aws_sns_topic.default.arn}"
        }
      ]
    })
  }
}

resource "aws_lambda_function" "default" {
  function_name = "dsb-blogging-assistant-lambda"
  role          = aws_iam_role.lambda_exec_role.arn

  image_uri    = data.aws_ecr_image.lambda_image_lookup.image_uri
  timeout      = 120 # 2 minutes
  package_type = "Image"

  environment {
    variables = {
      SNS_TOPIC_ARN        = aws_sns_topic.default.arn
      REPOSITORY_URL       = "https://github.com/The-DevSec-Blueprint/dsb-digest"
      YOUTUBE_CHANNEL_NAME = "Damien Burks | The DevSec Blueprint (DSB)"
    }
  }
  depends_on = [aws_ecr_repository.lambda_image]
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
        "Resource": "${aws_lambda_function.default.arn}",
        "Parameters": {
          "actionName": "getVideoId",
          "videoName.$": "$.videoName"
        },
        "ResultPath": "$.getVideoId",
        "Next": "Generate Blog Post with OpenAI"
      },
      "Generate Blog Post with OpenAI": {
        "Type": "Task",
        "Resource": "${aws_lambda_function.default.arn}",
        "Parameters": {
          "actionName": "generateBlogPost",
          "videoId.$": "$.getVideoId.videoId"
        },
        "ResultPath": "$.generateBlogPost",
        "Next": "Publish MD Blog to GitHub"
      },
      "Publish MD Blog to GitHub": {
        "Type": "Task",
        "Resource": "${aws_lambda_function.default.arn}",
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
        "Resource": "${aws_lambda_function.default.arn}",
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
        Sid    = ""
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