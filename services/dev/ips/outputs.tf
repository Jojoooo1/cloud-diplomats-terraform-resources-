output "ingress_nginx_address" {
  description = "Ingress nginx IP address"
  value       = module.static_ip_regional_ingress_nginx.addresses
}

output "ingress_argo_address" {
  description = "Ingress nginx IP address"
  value       = module.static_ip_global_ingress_argo.addresses
}
