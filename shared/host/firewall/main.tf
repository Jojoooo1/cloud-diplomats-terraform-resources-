locals {
  network = data.terraform_remote_state.network.outputs.network_self_link

  private_subnet_secondary_pod = data.terraform_remote_state.network.outputs.subnets_secondary_ranges_private[1]
  private_subnet_secondary_svc = data.terraform_remote_state.network.outputs.subnets_secondary_ranges_private[2]

  gcp_private_service_access_ranges = data.terraform_remote_state.network.outputs.subnets_gcp_private_service_access_ranges

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}

/******************************************
  Firewall Egress configuration
 *****************************************/

# By default deny all egress traffic!
resource "google_compute_firewall" "deny_all_egress" {
  project = var.project_id

  name        = "deny-all-egress"
  network     = local.network
  description = "By default deny all egress traffic (managed by terraform)"

  deny {
    protocol = "all"
  }

  priority  = 65530
  direction = "EGRESS"

  destination_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_all_egress" {
  project = var.project_id

  name        = "allow-all-egress"
  network     = local.network
  description = "Allow all egress traffic (managed by terraform)"

  allow {
    protocol = "all"
  }

  priority  = 1000
  direction = "EGRESS"

  target_tags        = ["allow-all-egress"]
  destination_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_gcp_private_service_access_egress" {
  project = var.project_id

  name        = "allow-gcp-private-service-access-egress"
  network     = local.network
  description = "Allow egress traffic to GCP private service access ranges from 'allow-gcp-private-service-access' (managed by terraform)"

  allow {
    protocol = "all"
  }

  priority  = 1000
  direction = "EGRESS"

  target_tags        = ["allow-gcp-private-service-access"]
  destination_ranges = [local.gcp_private_service_access_ranges]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

/******************************************
  Firewall Ingress configuration
 *****************************************/
resource "google_compute_firewall" "allow_ssh_from_iap_ingress" {
  project = var.project_id

  name        = "allow-ssh-from-iap-ingress"
  network     = local.network
  description = "Allow ingress traffic from IAP to 'allow-ssh-from-iap' (managed by terraform)"


  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  priority  = 1000
  direction = "INGRESS"

  target_tags   = ["allow-ssh-from-iap"]
  source_ranges = ["35.235.240.0/20"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# https://cloud.google.com/kubernetes-engine/docs/concepts/firewall-rules
# https://cloud.google.com/load-balancing/docs/https/setting-up-reg-ext-shared-vpc#configure_firewall_rules
resource "google_compute_firewall" "allow_http_ingress" {
  project = var.project_id

  # necessary for kubernetes ingresses of type (Network). Nginx ingress for example.
  name        = "allow-http-ingress"
  network     = local.network
  description = "Allow HTTP traffic to reach instances or k8s node (managed by terraform)"

  target_tags   = ["allow-http-ingress"]
  source_ranges = ["0.0.0.0/0"]

  priority  = "1000"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "allow_lb_health_check_from_gcp_ingress" {
  project = var.project_id

  # necessary for kubernetes ingress (Application (Classic)). GCE ingress for example.
  name        = "allow-lb-health-check-from-gcp-ingress"
  network     = local.network
  description = "Allow ingress traffic from GCP Load balancer health check (managed by terraform)"

  target_tags   = ["allow-lb-health-check-from-gcp"]
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  priority  = "1000"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "allow_nginx_webhook_admission_from_k8s_master_ingress" {
  project = var.project_id

  # necessary for nginx ingress to work.
  name        = "allow-nginx-webhook-admission-from-k8s-master-ingress"
  network     = local.network
  description = "Allow kubernetes (private) master to communicate with nginx webhook admission (managed by terraform)"

  target_tags   = ["allow-nginx-webhook-admission-from-k8s-master"]
  source_ranges = var.gke_master_ipv4_cidr_blocks

  priority  = "1000"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }
}