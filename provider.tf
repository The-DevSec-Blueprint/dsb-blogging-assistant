terraform {
  cloud {
    organization = "DSB"

    workspaces {
      name = "dsb-blogging-assistant"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}