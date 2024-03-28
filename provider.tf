terraform {
  cloud {
    organization = "DSB"

    workspaces {
      name = "dsb-blogging-assistant"
    }
  }
}