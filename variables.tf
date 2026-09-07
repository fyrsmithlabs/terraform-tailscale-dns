variable "dns_zone" {
  description = "DNS zone forwarded to the in-cluster resolver over the tailnet (no trailing dot), e.g. `example.com`."
  type        = string

  validation {
    condition     = !endswith(var.dns_zone, ".")
    error_message = "dns_zone must NOT include a trailing dot (Tailscale Split DNS expects a bare domain)."
  }

  validation {
    condition     = length(trimspace(var.dns_zone)) > 0
    error_message = "dns_zone must not be empty."
  }
}

variable "dns_device_hostname" {
  description = <<-EOT
    Tailscale device hostname of the in-cluster resolver. Must match the
    `tailscale.com/hostname` annotation on the resolver's Kubernetes Service.
    The device must already exist — deploy the resolver before applying this
    component, or the `tailscale_device` data source fails after its wait
    window.
  EOT
  type        = string

  validation {
    condition     = length(trimspace(var.dns_device_hostname)) > 0
    error_message = "dns_device_hostname must not be empty."
  }
}
