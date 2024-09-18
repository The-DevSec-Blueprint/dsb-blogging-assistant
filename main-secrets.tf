
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

resource "aws_ssm_parameter" "smartproxy_username" {
  name  = "/credentials/smartproxy/username"
  type  = "SecureString"
  value = var.PROXY_USERNAME
}

resource "aws_ssm_parameter" "smartproxy_password" {
  name  = "/credentials/smartproxy/password"
  type  = "SecureString"
  value = var.PROXY_PASSWORD
}