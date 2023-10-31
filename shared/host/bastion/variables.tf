variable "project_id" {
  description = "The project ID for the network"
  type        = string
}

variable "region" {
  description = "The region for subnetworks in the network"
  type        = string
}

variable "name" {
  description = "Host name of the bastion"
  type        = string
}
