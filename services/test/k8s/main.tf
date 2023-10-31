locals {
  network            = data.terraform_remote_state.network.outputs.network_name
  private_subnetwork = data.terraform_remote_state.network.outputs.subnets["us-east1/cl-dpl-us-east1-dev-private"].name

  bastion_private_ip = data.terraform_remote_state.bastion.outputs.ip_address

  gke_name = "gke-test-1"

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
  version = "28.0.0"

  project_id = var.project_id
  name       = local.gke_name

  # region     = var.region # REGIONAL CLUSTER
  regional           = false      # ZONAL CLUSTER
  zones              = [var.zone] #
  network_project_id = var.network_project_id
  network            = local.network
  subnetwork         = local.private_subnetwork

  ip_range_pods     = var.ip_range_pods
  ip_range_services = var.ip_range_services

  enable_private_endpoint = true
  enable_private_nodes    = true

  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  master_authorized_networks = [
    {
      cidr_block   = "${local.bastion_private_ip}/32"
      display_name = "bastion-host-dev"
    }
  ]

  release_channel             = "UNSPECIFIED"
  kubernetes_version          = "1.27.4-gke.900"
  datapath_provider           = "ADVANCED_DATAPATH" # enable dataplane V2 (cilium) https://isovalent.com/blog/post/cilium-hubble-cheat-sheet-observability/
  enable_shielded_nodes       = true
  enable_binary_authorization = true

  enable_vertical_pod_autoscaling      = true
  horizontal_pod_autoscaling           = true
  http_load_balancing                  = true
  network_policy                       = false # If dataplane V2 is enabled, the Calico add-on should be disabled.
  gce_pd_csi_driver                    = true
  filestore_csi_driver                 = true
  dns_cache                            = false
  monitoring_enable_managed_prometheus = false

  create_service_account = true
  grant_registry_access  = true
  registry_project_ids   = []

  remove_default_node_pool = true
  initial_node_count       = 1
  node_pools = [
    {
      name         = "node-pool-dev-01"
      machine_type = "e2-medium"
      # node_locations  = "us-east1-b,us-east1-c"
      image_type = "COS_CONTAINERD"
      version    = "1.27.4-gke.900"

      initial_node_count = 1
      min_count          = 1
      max_count          = 2
      spot               = false
      # UPDATE TO FALSE FOR PRODUCTION
      preemptible = true

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
      "allow-ssh-from-iap",
      "allow-all-egress", # Necessary for LB

      # Those are necessary since GCP service project does not have permission to create firewall rules automatically
      "allow-k8s-lb-ingress",
      "allow-k8s-lb-health-check",
      "allow-k8s-ingress-nginx-webhook-admission"
    ],
    "default-node-pool" : []
  }
}


/******************************************
  Kubernetes Workload identity configuration https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/v28.0.0/modules/workload-identity
 *****************************************/
module "workload_identity_external_secrets_operator" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "28.0.0"

  project_id = var.project_id

  cluster_name = module.gke.name
  location     = module.gke.location

  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
  name                = "external-secrets"
  namespace           = "external-secrets"
  roles               = ["roles/secretmanager.secretAccessor"]
}

module "workload_identity_external_dns" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "28.0.0"

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
}
