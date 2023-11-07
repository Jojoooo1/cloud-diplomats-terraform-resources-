
locals {
  network        = data.terraform_remote_state.network.outputs.network_self_link
  private_subnet = data.terraform_remote_state.network.outputs.subnets["us-east1/cloud-dpl-vpc-dev-us-east1-private"].self_link

  name = "bastion-host-dev"

  common_labels = {
    owned-by   = "platform"
    managed-by = "terraform"
    env        = "non-prod"
  }
}

/******************************************
  Bastion host
  SSH: gcloud compute ssh --project="<your-project>" --zone="us-east1-b" bastion-host-dev --tunnel-through-iap
  SQL: gcloud compute ssh --project="<your-project>" --zone="us-east1-b" bastion-host-dev --tunnel-through-iap -- '/usr/local/bin/cloud_sql_proxy --private-ip --address 0.0.0.0 <your-connection-name>' 
  GKE: gcloud compute ssh --project="<your-project>" --zone="us-east1-b" bastion-host-dev --tunnel-through-iap -- -L8888:127.0.0.1:8888
 *****************************************/
module "bastion_with_iap" {
  source  = "terraform-google-modules/bastion-host/google"
  version = "6.0.0"

  project = var.project_id
  network = local.network
  subnet  = local.private_subnet
  zone    = var.zone

  preemptible = true

  name                 = local.name
  service_account_name = local.name
  create_firewall_rule = false # already create in the firewall folder
  machine_type         = "e2-micro"
  disk_size_gb         = 10
  startup_script       = <<-EOF
    #!/bin/bash

    sudo apt-get update -y
    sudo apt install wget

    echo "****************************************************************"
    echo "installing cloud-ops-agent:"
    echo "****************************************************************"
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install

    echo "****************************************************************"
    echo "installing Cloud SQL proxy:"
    echo "****************************************************************"
    sudo wget https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.7.1/cloud-sql-proxy.linux.amd64 -O cloud_sql_proxy
    sudo chmod +x cloud_sql_proxy
    sudo mv cloud_sql_proxy /usr/local/bin

    echo "****************************************************************"
    echo "installing PSQL Client: (not recommended, only used for debugging)" 
    echo "****************************************************************"
    sudo apt-get install -y postgresql-client

    echo "****************************************************************"
    echo "installing tinyproxy:"
    echo "****************************************************************"
    sudo apt-get install -y tinyproxy

  EOF

  # Necessary if your user does not have the tunnelResourceAccessor roles.
  # members = [
  #   "user:jonathan@cloud-diplomats.com" 
  # ]

  tags   = ["allow-igw", "allow-ssh-from-iap", "allow-all-egress"]
  labels = local.common_labels
}

# uncomment if want to use the bastion host to connect to the Cloud SQL instance
# resource "google_project_iam_binding" "store_user" {
#   project = var.service_dev_project_id
#   role    = "roles/cloudsql.client"
#   members = [
#     "serviceAccount:${module.bastion_with_iap.service_account}"
#   ]
# }
