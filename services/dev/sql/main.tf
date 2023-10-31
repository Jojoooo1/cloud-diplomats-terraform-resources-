
locals {
  network                         = data.terraform_remote_state.network.outputs.network_self_link
  gcp_private_service_access_name = data.terraform_remote_state.network.outputs.subnets_gcp_private_service_access_name

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}

/******************************************
  Database PostgresQL configuration
 *****************************************/

module "postgres" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "17.0.0"

  project_id           = var.project_id
  name                 = "test"
  random_instance_name = true

  region = var.region
  zone   = var.zone

  # Configuration
  tier                = "db-g1-small"
  database_version    = "POSTGRES_15"
  edition             = "ENTERPRISE" # Use ENTERPRISE_PLUS for better performance
  availability_type   = "ZONAL"      # use "REGIONAL" if you want to have HA
  disk_autoresize     = true
  deletion_protection = false # block terraform to delete the database

  # Database
  enable_default_db = true
  db_name           = "api"

  # Users
  enable_default_user = true
  user_name           = "user"
  user_password       = var.password

  # Insights
  insights_config = {
    query_insights_enabled  = true
    query_string_length     = 4500
    record_application_tags = true
    record_client_address   = true
  }

  # Connectivity
  ip_configuration = {
    ipv4_enabled        = false
    private_network     = local.network
    require_ssl         = false
    authorized_networks = []
    allocated_ip_range  = local.gcp_private_service_access_name

    enable_private_path_for_google_cloud_services = true
  }

  # Maintenance & backup
  maintenance_window_day          = 7
  maintenance_window_hour         = 3
  maintenance_window_update_track = "stable"

  backup_configuration = {
    enabled          = true
    retained_backups = 7
    retention_unit   = "COUNT"
    start_time       = "04:00"
    location         = "us"

    point_in_time_recovery_enabled = false
    transaction_log_retention_days = "3"
  }

  # Use https://pgtune.leopard.in.ua to tune the initial configuration
  database_flags = [
    { name = "cloudsql.logical_decoding", value = "on" }
  ]

  user_labels = local.common_labels
}
