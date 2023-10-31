output "hostname" {
  description = "Internal IP address of the bastion host"
  value       = module.bastion_with_iap.hostname

}

output "service_account" {
  description = "Host name of the bastion"
  value       = module.bastion_with_iap.service_account
}

output "ip_address" {
  description = "Internal IP address of the bastion host"
  value       = module.bastion_with_iap.ip_address
}
