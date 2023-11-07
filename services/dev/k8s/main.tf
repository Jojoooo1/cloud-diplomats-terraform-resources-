locals {
  network = data.terraform_remote_state.network.outputs.network_name

  private_subnet                             = data.terraform_remote_state.network.outputs.subnets["us-east1/cloud-dpl-vpc-dev-us-east1-private"].name
  private_subnet_secondary_range_gke_pods    = data.terraform_remote_state.network.outputs.subnets_secondary_ranges_private[1].range_name
  private_subnet_secondary_range_gke_service = data.terraform_remote_state.network.outputs.subnets_secondary_ranges_private[2].range_name

  bastion_private_ip = data.terraform_remote_state.bastion.outputs.ip_address

  gke_name = "cloud-dpl-gke-dev"

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}


/******************************************
  Kubernetes configuration https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/private-cluster
 *****************************************/
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "29.0.0"

  project_id = var.project_id
  name       = local.gke_name

  # Update: to regional for production
  # region     = var.region # REGIONAL CLUSTER
  regional = false # ZONAL CLUSTER
  zones    = [var.zone]

  network_project_id = var.network_project_id # host project
  network            = local.network
  subnetwork         = local.private_subnet

  ip_range_pods     = local.private_subnet_secondary_range_gke_pods
  ip_range_services = local.private_subnet_secondary_range_gke_service

  enable_private_endpoint = true
  enable_private_nodes    = true

  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  master_authorized_networks = [
    {
      cidr_block   = "${local.bastion_private_ip}/32"
      display_name = "bastion-host-dev"
    }
  ]

  release_channel    = "UNSPECIFIED"
  kubernetes_version = "1.27.3-gke.100"    # https://cloud.google.com/kubernetes-engine/docs/release-notes
  datapath_provider  = "ADVANCED_DATAPATH" # enable dataplane V2 (cilium)

  # Security
  enable_shielded_nodes               = true
  enable_binary_authorization         = true
  deletion_protection                 = false
  security_posture_mode               = "BASIC"
  security_posture_vulnerability_mode = "VULNERABILITY_BASIC"

  # Features
  enable_vertical_pod_autoscaling      = true
  horizontal_pod_autoscaling           = true
  http_load_balancing                  = true
  network_policy                       = false # If dataplane V2 is enabled, the Calico add-on should be disabled.
  gce_pd_csi_driver                    = true
  filestore_csi_driver                 = true
  gcs_fuse_csi_driver                  = true
  dns_cache                            = false
  monitoring_enable_managed_prometheus = false
  enable_cost_allocation               = true
  # enable_gcfs                          = true # not present for private cluster module yet.

  create_service_account = true
  grant_registry_access  = true
  registry_project_ids   = []

  remove_default_node_pool = true
  initial_node_count       = 1
  node_pools = [
    {
      name         = "${local.gke_name}-node-pool-01"
      machine_type = "e2-medium"
      image_type   = "COS_CONTAINERD"
      version      = "1.27.3-gke.100"

      initial_node_count = 1
      min_count          = 1
      max_count          = 2

      # Update to false for production
      spot = true

      auto_upgrade = false
      auto_repair  = true
      autoscaling  = true

      disk_type       = "pd-standard"
      local_ssd_count = 0
      disk_size_gb    = 100

      enable_gcfs                 = true
      enable_integrity_monitoring = true
      enable_secure_boot          = true
      logging_variant             = "DEFAULT"
    }
  ]

  node_pools_tags = {
    "all" : [
      "allow-igw",
      "allow-ssh-from-iap",
      "allow-all-egress",

      # Those are necessary since GCP service project does not have permission to create firewall rules automatically in host project
      "allow-http-ingress",
      "allow-lb-health-check-from-gcp",
      "allow-nginx-webhook-admission-from-k8s-master"
    ],
    "default-node-pool" : []
  }
}


/******************************************
  Kubernetes Workload identity configuration https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/v28.0.0/modules/workload-identity
 *****************************************/
module "workload_identity_external_secrets_operator" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "29.0.0"

  project_id = var.project_id

  cluster_name = module.gke.name
  location     = module.gke.location

  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
  name                = "external-secrets"
  namespace           = "external-secrets"
  roles               = ["roles/secretmanager.secretAccessor"]

  depends_on = [module.gke]
}

module "workload_identity_external_dns" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "29.0.0"

  project_id = var.project_id

  cluster_name = module.gke.name
  location     = module.gke.location

  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
  name                = "external-dns"
  namespace           = "external-dns"

  roles = []
  additional_projects = {
    "${var.project_dns_id}" : ["roles/dns.admin"]
  }

  depends_on = [module.gke]
}
