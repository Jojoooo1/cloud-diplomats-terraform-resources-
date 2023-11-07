terraform {
  required_version = ">= 1.5.7"

  # rand="$(echo $RANDOM)" && gsutil mb -p "<your-project-name>" -l us -b on "gs://tf-state-$rand" && gsutil versioning set on "gs://tf-state-$rand"
  backend "gcs" {
    bucket = "tf-state-17597"
    prefix = "terraform/state/k8s/dev"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.4"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.4"
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = "tf-state-19590"
    prefix = "terraform/state/network/shared-vpc"
  }
}

data "terraform_remote_state" "bastion" {
  backend = "gcs"

  config = {
    bucket = "tf-state-19590"
    prefix = "terraform/state/vm/bastion"
  }
}
