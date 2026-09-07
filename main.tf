# tailscale-dns
#
# Tailnet Split DNS for a cluster domain. Makes a zone resolve OVER THE TAILNET,
# internal-only:
#
#   tailnet client ──query svc.example.com──▶ Tailscale (MagicDNS)
#       └─ Split DNS: example.com ──forward──▶ in-cluster resolver device
#              └─ answers with the ingress gateway tailnet IP (100.x)
#                     └─ client routes to it over the tailnet
#
# Because the zone is forwarded to a tailnet-only nameserver and never published
# to public DNS, the names resolve ONLY for tailnet members. This is required
# when the tailnet runs MagicDNS with "Override local DNS" on — without a Split
# DNS entry the zone would not resolve on-tailnet at all.
#
# Apply order (HUMAN-GATED): deploy the in-cluster resolver FIRST so the
# Tailscale Kubernetes operator registers its device; this component then
# discovers that device's tailnet IP and points the Split DNS zone at it.
# Applying before the device exists fails in the data source, not silently.
#
# Auth: the provider reads OAuth client credentials from the environment
#   TAILSCALE_OAUTH_CLIENT_ID / TAILSCALE_OAUTH_CLIENT_SECRET
# (never in code). The OAuth client needs the `dns` (write) and
# `devices:core:read` scopes. See README.md.

provider "tailscale" {
  # tailnet + credentials come from the environment (OAuth client). With an
  # OAuth client the tailnet defaults to that client's tailnet ("-").
}

# Discover the in-cluster resolver's tailnet IP by its pinned hostname. The
# resolver's Service is published by the Tailscale operator as this device
# (its `tailscale.com/hostname` annotation must equal var.dns_device_hostname).
data "tailscale_device" "dns" {
  hostname = var.dns_device_hostname
  wait_for = "60s"
}

# Forward the cluster zone to the in-cluster resolver, for tailnet members only.
resource "tailscale_dns_split_nameservers" "cluster" {
  domain      = var.dns_zone
  nameservers = [data.tailscale_device.dns.addresses[0]]
}
