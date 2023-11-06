locals {

  vpc_name = "cloud-dpl-vpc-dev"

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}

/******************************************
  Shared VPC configuration
 *****************************************/
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "8.0"

  project_id   = var.project_id
  network_name = local.vpc_name

  shared_vpc_host                        = "true"
  delete_default_internet_gateway_routes = "true"
  routing_mode                           = "GLOBAL"

  subnets = [
    {
      subnet_name               = "${local.vpc_name}-${var.region}-public"
      subnet_ip                 = "10.0.0.0/19"
      subnet_region             = "us-east1"
      subnet_private_access     = "true"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    },
    {
      subnet_name               = "${local.vpc_name}-${var.region}-private"
      subnet_ip                 = "10.0.32.0/19"
      subnet_region             = "us-east1"
      subnet_private_access     = "true"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    },
  ]

  # Google Cloud security foundations guide v3: page 63
  # Some use cases, such as container-based workloads, can require additional aggregates. These need to be defined as subnet secondary ranges. 
  # For these cases, you can use address ranges that are taken from the reserved RFC 6598 (Shared Address Space address range 100.64.0.0/10 -> 100.64.0.0 until 100.127.255.255).
  secondary_ranges = {
    "${local.vpc_name}-${var.region}-public" = [
      {
        range_name    = "${local.vpc_name}-${var.region}-public-secondary"
        ip_cidr_range = "100.64.0.0/19"
      },
      {
        range_name    = "${local.vpc_name}-${var.region}-public-secondary-gke-pod"
        ip_cidr_range = "100.64.32.0/19",
      },
      {
        range_name    = "${local.vpc_name}-${var.region}-public-secondary-gke-svc"
        ip_cidr_range = "100.64.64.0/19",
      },
    ]
    "${local.vpc_name}-${var.region}-private" = [
      {
        range_name    = "${local.vpc_name}-${var.region}-private-secondary"
        ip_cidr_range = "100.65.0.0/19"
      },
      {
        range_name    = "${local.vpc_name}-${var.region}-private-secondary-gke-pod"
        ip_cidr_range = "100.65.32.0/19",
      },
      {
        range_name    = "${local.vpc_name}-${var.region}-private-secondary-gke-svc"
        ip_cidr_range = "100.65.64.0/19",
      },
    ]
  }

  routes = [
    {
      name              = "rt-${local.vpc_name}-1000-egress-internet-default"
      description       = "Tag based route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "allow-igw"
      next_hop_internet = "true"
      priority          = "1000"
    }
  ]

}

/******************************************
  NAT Cloud Router & NAT config (note: Cloud NAT implements outbound NAT in conjunction with a *DEFAULT ROUTE* to allow your instances to reach the internet => meaning you need to use the "allow-igw" tag)
 *****************************************/
resource "google_compute_router" "vpc_router" {
  project = var.project_id

  name    = "${local.vpc_name}-${var.region}-nat-router"
  region  = var.region
  network = module.vpc.network_self_link
}

resource "google_compute_address" "vpc_nat_ip" {
  project = var.project_id

  name   = "${local.vpc_name}-${var.region}-egress-nat-ip"
  region = var.region
}

resource "google_compute_router_nat" "vpc_nat" {
  project = var.project_id

  name   = "${local.vpc_name}-${var.region}-egress-nat"
  region = var.region
  router = google_compute_router.vpc_router.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.vpc_nat_ip.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # subnetwork {
  #   name                    = module.vpc.subnets["${var.region}/${local.vpc_name}-${var.region}-public"].self_link
  #   source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  # }

  subnetwork {
    name                    = module.vpc.subnets["${var.region}/${local.vpc_name}-${var.region}-private"].self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    filter = "TRANSLATIONS_ONLY"
    enable = true
  }
}


/***************************************************************
  Configure Private Networking for GCP Services like Cloud SQL [...]
 **************************************************************/
resource "google_compute_global_address" "gcp_private_service_access_address" {
  project = var.project_id

  name    = "${local.vpc_name}-peering-gcp-private-service-access"
  network = module.vpc.network_self_link

  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"

  address       = "10.100.0.0"
  prefix_length = 16
}

resource "google_service_networking_connection" "gcp_private_vpc_connection" {
  network = module.vpc.network_self_link
  service = "servicenetworking.googleapis.com"

  reserved_peering_ranges = [google_compute_global_address.gcp_private_service_access_address.name]
}
