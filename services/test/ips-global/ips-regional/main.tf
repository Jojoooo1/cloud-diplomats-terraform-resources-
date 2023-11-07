locals {
  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}


/******************************************
  Regional IP configuration
 *****************************************/

module "static_ips_regional" {
  source  = "terraform-google-modules/address/google"
  version = "3.1.3"

  project_id   = var.project_id
  region       = var.region
  address_type = "EXTERNAL"

  names = [
    "cl-dpl-service-test-rap0-k8s-test-nginx-ingress",
  ]

}
