output "fw_allow_ssh_from_iap_tag" {
  value       = google_compute_firewall.allow_ssh_from_iap_ingress.target_tags
  description = "The name of the firewall rules to allow ssh from IAP"
}

output "fw_allow_all_egress_tag" {
  value       = google_compute_firewall.allow_all_egress.target_tags
  description = "The name of the firewall rules to allow all egress traffic"
}

