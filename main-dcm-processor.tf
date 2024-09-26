# ECR Repository 
data "aws_ecr_image" "dcm_processor_lambda_image_lookup" {
  repository_name = aws_ecr_repository.dcm_processor_lambda_image.name
  most_recent     = true
}

resource "aws_ecr_repository" "dcm_processor_lambda_image" {
  name         = "dsb-blogging-assistant-dcm-processor-lambda-image"
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "dcm_processor_lambda_image_lifecycle_policy" {
  repository = aws_ecr_repository.dcm_processor_lambda_image.name

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

data "aws_iam_policy_document" "dcm_lambda_exec_role_inline_policy" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.default.arn]
  }
  statement {
    actions   = ["states:SendTaskSuccess"]
    resources = [local.default_sfn_arn]
  }
  statement {
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
    ]
  }
}
resource "aws_iam_role" "dcm_lambda_exec_role" {
  name = "dsb-ba-dcm-processor-lambda-exec-role"
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
    name   = "InlinePolicy"
    policy = data.aws_iam_policy_document.dcm_lambda_exec_role_inline_policy.json
  }
}

resource "aws_lambda_function" "dcm_processor_lambda_func" {
  function_name = "dsb-blogging-assistant-dcm-processor"
  role          = aws_iam_role.dcm_lambda_exec_role.arn

  image_uri    = data.aws_ecr_image.dcm_processor_lambda_image_lookup.image_uri
  timeout      = 120 # 2 minutes
  package_type = "Image"

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.default.arn
    }
  }
  depends_on = [aws_ecr_repository.dcm_processor_lambda_image]
}

resource "aws_lambda_permission" "url_invoke_permissions" {
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.dcm_processor_lambda_func.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_function_event_invoke_config" "dcm_processor_inv_event_conf" {
  function_name          = aws_lambda_function.dcm_processor_lambda_func.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [aws_lambda_function_event_invoke_config.core_inv_event_conf]
}

resource "aws_lambda_function_url" "dcm_processor_lambda_url" {
  function_name      = aws_lambda_function.dcm_processor_lambda_func.function_name
  authorization_type = "NONE"
}