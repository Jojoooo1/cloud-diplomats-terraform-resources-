output "network_name" {
  value       = module.vpc.network_name
  description = "The name of the VPC being created"
}

output "network_self_link" {
  value       = module.vpc.network_self_link
  description = "The URI of the VPC being created"
}

output "subnets_names" {
  value       = module.vpc.subnets_names
  description = "The names of the subnets being created"
}

output "subnets_ips" {
  value       = module.vpc.subnets_ips
  description = "The IPs and CIDRs of the subnets being created"
}

output "subnets_self_links" {
  value       = module.vpc.subnets_self_links
  description = "The self-links of subnets being created"
}

output "subnets" {
  value       = module.vpc.subnets
  description = "A map with keys of form subnet_region/subnet_name and values being the outputs of the google_compute_subnetwork resources used to create corresponding subnets."
}

output "subnets_regions" {
  value       = module.vpc.subnets_regions
  description = "The region where the subnets will be created"
}

output "subnets_private_access" {
  value       = module.vpc.subnets_private_access
  description = "Whether the subnets have access to Google API's without a public IP"
}

output "subnets_flow_logs" {
  value       = module.vpc.subnets_flow_logs
  description = "Whether the subnets have VPC flow logs enabled"
}

# output "subnets_secondary_ranges" {
#   value       = module.vpc.subnets_secondary_ranges
#   description = "The secondary ranges associated with these subnets"
# }

output "subnets_secondary_ranges_public" {
  value       = module.vpc.subnets["${var.region}/${local.vpc_name}-${var.region}-public"].secondary_ip_range
  description = "The secondary ranges associated with the public subnets"
}

output "subnets_secondary_ranges_private" {
  value       = module.vpc.subnets["${var.region}/${local.vpc_name}-${var.region}-private"].secondary_ip_range
  description = "The secondary ranges associated with the private subnets"
}

output "subnets_gcp_private_service_access_ranges" {
  value       = format("%s/%s", google_compute_global_address.gcp_private_service_access_address.address, google_compute_global_address.gcp_private_service_access_address.prefix_length)
  description = "The subnet of the reserved peering range for GCP private service access"
}

output "subnets_gcp_private_service_access_name" {
  value       = google_compute_global_address.gcp_private_service_access_address.name
  description = "The subnet name of the reserved peering range for GCP private service access"
}

output "vpc_nat_ip" {
  value       = google_compute_address.vpc_nat_ip.address
  description = "IP for NAT gateway"
}
