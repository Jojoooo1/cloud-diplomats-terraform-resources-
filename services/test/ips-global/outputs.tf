output "addresses_argo" {
  description = "List of address values managed by this module (e.g. [\"1.2.3.4\"])"
  value       = module.static_ip_global_argo.addresses
}

output "names_argo" {
  description = "List of address resource names managed by this module (e.g. [\"gusw1-dev-fooapp-fe-0001-a-0001-ip\"])"
  value       = module.static_ip_global_argo.names
}

output "dns_fqdns_argo" {
  description = "List of DNS fully qualified domain names registered in Cloud DNS.  (e.g. [\"gusw1-dev-fooapp-fe-0001-a-001.example.com\", \"gusw1-dev-fooapp-fe-0001-a-0002.example.com\"])"
  value       = module.static_ip_global_argo.dns_fqdns
}
