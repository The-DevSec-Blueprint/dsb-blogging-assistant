terraform {
  cloud {
    workspaces {
      name = "dsb-blogging-assistant-ecr"
    }
  }
}

provider "aws" {
  region = var.region
}
