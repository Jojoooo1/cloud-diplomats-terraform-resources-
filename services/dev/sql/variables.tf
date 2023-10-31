variable "project_id" {
  description = "The project ID"
  type        = string
}

variable "region" {
  description = "The region of the Cloud SQL resources"
  type        = string
}

variable "zone" {
  description = "The zone for the master instance"
  type        = string
}

variable "password" {
  description = "The password for created user"
  type        = string
  sensitive   = true
}
