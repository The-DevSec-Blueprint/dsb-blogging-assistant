data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_ecr_image" "subscriber_image_lookup" {
  repository_name = "${var.resource_prefix}-sub-lambda-image"
  most_recent     = true
}

data "aws_ecr_image" "vdl_image_lookup" {
  repository_name = "${var.resource_prefix}-vdl-image"
  most_recent     = true
}

data "aws_ecr_image" "core_image_lookup" {
  repository_name = "${var.resource_prefix}-core-lambda-image"
  most_recent     = true
}

data "aws_ecr_image" "des_image_lookup" {
  repository_name = "${var.resource_prefix}-des-lambda-image"
  most_recent     = true
}