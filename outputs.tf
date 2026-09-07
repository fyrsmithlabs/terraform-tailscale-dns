output "dns_zone" {
  description = "Zone forwarded to the in-cluster resolver over the tailnet."
  value       = tailscale_dns_split_nameservers.cluster.domain
}

output "resolver_tailnet_ips" {
  description = "Tailnet IP(s) of the in-cluster resolver the zone is forwarded to. The first address is the one the Split DNS entry uses."
  value       = data.tailscale_device.dns.addresses
}

output "resolver_device_hostname" {
  description = "Tailscale device hostname of the in-cluster resolver."
  value       = var.dns_device_hostname
}
