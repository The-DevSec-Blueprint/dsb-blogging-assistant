terraform {
  cloud {
    workspaces {
      name = "dsb-blogging-assistant"
    }
  }
}

provider "aws" {
  region = var.region
}
