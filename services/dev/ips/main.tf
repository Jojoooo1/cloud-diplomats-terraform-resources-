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

# Service of type load balancer (like ingress nginx) create a passthrough network load balancer (https://cloud.google.com/load-balancing/docs/choosing-load-balancer#lb-summary)
# This load balancer is a regional resource, and is associated with a single region.

module "static_ip_regional_ingress_nginx" {
  source  = "terraform-google-modules/address/google"
  version = "3.1.3"

  project_id   = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
  global       = false

  names = [
    "${var.project_id}-k8s-ingress-nginx",
  ]

}


/******************************************
  Global IP configuration
 *****************************************/
module "static_ip_global_ingress_argo" {
  source  = "terraform-google-modules/address/google"
  version = "3.1.3"

  project_id   = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
  global       = true

  # enable_cloud_dns = true
  # dns_project      = "var.dns_project_id
  # dns_domain       = "cloud-diplomats.com"
  # dns_managed_zone = "cloud-diplomats-com"

  # Warning: do not update name convention or it will break the ingress IP annotations in ArgoCD
  # ${ARGOCD_ENV_PROJECT}-k8s-ingress-argo
  names = [
    "${var.project_id}-k8s-ingress-argo"
  ]

  # dns_short_names = [
  #   "argo-dev"
  # ]

}

module "static_ip_global_ingress_rabbitmq" {
  source  = "terraform-google-modules/address/google"
  version = "3.1.3"

  project_id   = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
  global       = true

  # enable_cloud_dns = true
  # dns_project      = "var.dns_project_id"
  # dns_domain       = "cloud-diplomats.com"
  # dns_managed_zone = "cloud-diplomats-com"

  names = [
    "${var.project_id}-k8s-ingress-rabbitmq"
  ]

}
