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
