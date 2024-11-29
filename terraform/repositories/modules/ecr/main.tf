resource "aws_ecr_repository" "this" {
  name         = var.name
  force_delete = var.force_delete
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy
}
