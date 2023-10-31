variable "project_id" {
  description = "The project ID for the network"
  type        = string
}

variable "region" {
  description = "The region for subnetworks in the network"
  type        = string
}

# https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke
variable "gke_master_ipv4_cidr_blocks" {
  description = "ipv4 cidr blocks to allow communication between nginx webhook admission and master node for private cluster"
  type        = list(string)
}
