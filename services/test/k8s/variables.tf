variable "project_id" {
  description = "The project ID"
  type        = string
}

variable "project_dns_id" {
  description = "The project ID for the DNS zone"
  type        = string
}

variable "region" {
  description = "The region for the GKE cluster"
  type        = string
}

variable "zone" {
  description = "The zone for the GKE cluster"
  type        = string
}

variable "network_project_id" {
  type        = string
  description = "The GCP project housing the VPC network to host the cluster in"
}

variable "ip_range_pods" {
  type        = string
  description = "The name of the secondary subnet ip range to use for pods"
}

variable "ip_range_services" {
  type        = string
  description = "The name of the secondary subnet range to use for services"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation used for the hosted master network"
}
