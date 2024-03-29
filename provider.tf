terraform {
  cloud {
    organization = "DSB"

    workspaces {
      name = "dsb-blogging-assistant"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}