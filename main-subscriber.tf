# ECR Repository
data "aws_ecr_image" "sub_lambda_image_lookup" {
  repository_name = aws_ecr_repository.sub_lambda_image.name
  most_recent     = true
}

resource "aws_ecr_repository" "sub_lambda_image" {
  name         = "dsb-blogging-assistant-sub-lambda-image"
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "sub_lambda_image_lifecycle_policy" {
  repository = aws_ecr_repository.sub_lambda_image.name

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
resource "aws_lambda_function" "sub_lambda_func" {
  function_name = "dsb-blogging-assistant-sub-lambda"
  role          = aws_iam_role.lambda_exec_role.arn

  image_uri    = data.aws_ecr_image.sub_lambda_image_lookup.image_uri
  timeout      = 120 # 2 minutes
  package_type = "Image"

  environment {
    variables = {
      TOPIC_URL    = aws_alb.application_load_balancer.dns_name
      CALLBACK_URL = "https://www.youtube.com/xml/feeds/videos.xml?channel_id=UCOSYuY_e_r5GtVdlCVwY83Q"
    }
  }
  depends_on = [aws_ecr_repository.sub_lambda_image]
}