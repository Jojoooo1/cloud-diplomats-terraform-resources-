<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.83 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.83 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.83 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.allow_all_egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_gcp_private_service_access_egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_ssh_from_iap_ingress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.deny_all_egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [terraform_remote_state.network](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID for the network | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region for subnetworks in the network | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fw_allow_all_egress_tag"></a> [fw\_allow\_all\_egress\_tag](#output\_fw\_allow\_all\_egress\_tag) | The name of the firewall rules to allow all egress traffic |
| <a name="output_fw_allow_ssh_from_iap_tag"></a> [fw\_allow\_ssh\_from\_iap\_tag](#output\_fw\_allow\_ssh\_from\_iap\_tag) | The name of the firewall rules to allow ssh from IAP |
<!-- END_TF_DOCS -->