terraform {
  required_version = ">= 1.5.7"

  backend "gcs" {
    bucket = "tf-state-19590"
    prefix = "terraform/state/vm/bastion"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.4.0"
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = "tf-state-19590"
    prefix = "terraform/state/network/shared-host"
  }
}

data "terraform_remote_state" "firewall" {
  backend = "gcs"

  config = {
    bucket = "tf-state-19590"
    prefix = "terraform/state/firewall"
  }
}

data "terraform_remote_state" "dev_services" {
  backend = "gcs"

  config = {
    bucket = "tf-state-16824"
    prefix = "terraform/state/projects/development/services"
  }
}
