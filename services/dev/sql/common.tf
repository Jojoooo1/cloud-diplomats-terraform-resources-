terraform {
  required_version = ">= 1.5.7"

  # rand="$(echo $RANDOM)" && gsutil mb -p "<your-project-name>" -l us -b on "gs://tf-state-$rand" && gsutil versioning set on "gs://tf-state-$rand"
  backend "gcs" {
    bucket = "tf-state-30994"
    prefix = "terraform/state/sql/postgres-dev"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.4.O"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.4.O"
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = "tf-state-16958"
    prefix = "terraform/state/network/shared-host"
  }
}
