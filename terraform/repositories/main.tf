module "subscriber_repo" {
  source = "./modules/ecr"
  name   = "${var.resource_prefix}-sub-lambda-image"
}

module "video_drop_listener_repo" {
  source = "./modules/ecr"
  name   = "${var.resource_prefix}-vdl-image"
}

module "core_lambda_repo" {
  source = "./modules/ecr"
  name   = "${var.resource_prefix}-core-lambda-image"
}

module "des_lambda_repo" {
  source = "./modules/ecr"
  name   = "${var.resource_prefix}-des-lambda-image"
}
