provider "aws" {
  region = "us-east-1"
}

resource "aws_sns_topic" "default" {
  name = "dsb-blogging-assistant-yt-topic"
}