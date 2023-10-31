
locals {
  network                      = data.terraform_remote_state.network.outputs.network_self_link
  private_subnet_primary       = data.terraform_remote_state.network.outputs.subnets["us-east1/cl-dpl-us-east1-dev-private"].ip_cidr_range
  private_subnet_secondary_pod = data.terraform_remote_state.network.outputs.subnets["us-east1/cl-dpl-us-east1-dev-private"].secondary_ip_range[1]
  private_subnet_secondary_svc = data.terraform_remote_state.network.outputs.subnets["us-east1/cl-dpl-us-east1-dev-private"].secondary_ip_range[2]

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

# Important: By default deny all egress traffic
resource "google_compute_firewall" "deny_all_egress" {
  project = var.project_id

  name        = "deny-all-egress"
  network     = local.network
  description = "By defaumt deny all egress traffic (managed by terraform)"

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

  name        = "allow-all-gcp-private-service-access-egress"
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

/******************************************
  Firewall Kubernetes configuration
 *****************************************/

# https://cloud.google.com/load-balancing/docs/https/setting-up-reg-ext-shared-vpc#configure_firewall_rules
# https://cloud.google.com/kubernetes-engine/docs/concepts/firewall-rules

resource "google_compute_firewall" "allow_k8s_lb_health_check" {
  project = var.project_id

  # necessary for GCE ingress (Application (Classic))
  name    = "allow-k8s-lb-health-check"
  network = local.network

  target_tags   = ["allow-k8s-lb-health-check"]
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  description   = "Allow GCP to process Load balancer health check (managed by terraform)"

  priority  = "1000"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "allow_k8s_lb_ingress" {
  project = var.project_id

  # necessary for Nginx ingress (Network (Passthrough target-pool))
  name        = "allow-k8s-lb-ingress"
  network     = local.network
  description = "Allow ingress traffic to reach kubernetes service backed by a Load balancer (managed by terraform)"

  target_tags   = ["allow-k8s-lb-ingress"]
  source_ranges = ["0.0.0.0/0"]

  priority  = "1000"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "allow_k8s_nginx_ingress_webhook_admission" {
  project = var.project_id

  name        = "allow-k8s-ingress-nginx-webhook-admission"
  network     = local.network
  description = "Allow kubernetes (private) master to communicate with nginx webhook admission (managed by terraform)"

  target_tags   = ["allow-k8s-ingress-nginx-webhook-admission"]
  source_ranges = var.gke_master_ipv4_cidr_blocks

  priority  = "1000"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }
}
