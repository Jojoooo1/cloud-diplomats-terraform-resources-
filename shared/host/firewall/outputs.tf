output "fw_allow_ssh_from_iap_tag" {
  value       = google_compute_firewall.allow_ssh_from_iap_ingress.target_tags
  description = "The name of the firewall rules to allow ssh from IAP"
}

output "fw_allow_all_egress_tag" {
  value       = google_compute_firewall.allow_all_egress.target_tags
  description = "The name of the firewall rules to allow all egress traffic"
}

output "service_dev_gke_master_ipv4_cidr_blocks" {
  value       = var.gke_master_ipv4_cidr_blocks
  description = "The master IP range of the GKE cluster in service-dev project"
}

