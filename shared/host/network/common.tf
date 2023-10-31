terraform {
  required_version = ">= 1.5.7"

  # rand="$(echo $RANDOM)" && gsutil mb -p <project-name> -l us -b on "gs://tf-state-$rand" && gsutil versioning set on "gs://tf-state-$rand"
  backend "gcs" {
    bucket = "tf-state-19590"
    prefix = "terraform/state/network/shared-vpc"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.4.0"
    }
  }
}
