locals {
  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}

/******************************************
  Identity aware proxy configuration: https://cloud.google.com/iap/docs/programmatic-oauth-clients
 *****************************************/

# Necessary to create one brand (Oauth consent screen) per project
resource "google_iap_brand" "project_brand" {
  project = var.project_id

  application_title = "Cloud diplomate internal"
  support_email     = "jonathan.chevalier@cloud-diplomate.com"
}

# Can not bind automatically IAP backend and IAM policy https://github.com/hashicorp/terraform-provider-google/issues/4515
# resource "google_iap_web_backend_service_iam_binding" "k8s_test_rabbitmq" {
#   project = var.project_id
#   web_backend_service = var.k8s_test_rabbitmq_backend_service_name
#   role = "roles/iap.httpsResourceAccessor"
#   members = [
#     "user:jonathan.chevalier@cloud-diplomate.com",
#   ]
# }
