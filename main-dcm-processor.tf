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

resource "aws_lambda_function" "processor_decision_maker_lambda_func" {
  function_name = "dsb-blogging-assistant-dcm-processor"
  role          = aws_iam_role.lambda_exec_role.arn

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

resource "aws_lambda_function_url" "processor_decision_maker_url" {
  function_name      = aws_lambda_function.processor_decision_maker_lambda_func.function_name
  authorization_type = "NONE"
}