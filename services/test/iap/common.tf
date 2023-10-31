terraform {
  required_version = ">= 1.5.7"

  # rand="$(echo $RANDOM)" && gsutil mb -p "<your-project-name>" -l us -b on "gs://tf-state-$rand" && gsutil versioning set on "gs://tf-state-$rand"
  backend "gcs" {
    bucket = "tf-state-28088"
    prefix = "terraform/state/iap"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.1.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.1.0"
    }
  }
}
