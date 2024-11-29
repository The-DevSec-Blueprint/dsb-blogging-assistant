variable "name" {
  description = "The name of the ECR repository."
  type        = string
}

variable "force_delete" {
  description = "Whether to force delete the repository even if it contains images."
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "The JSON lifecycle policy for the repository."
  type        = string
  default     = <<EOF
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
