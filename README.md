# terraform-tailscale-dns

Terraform component that points a tailnet **Split DNS** zone at an in-cluster resolver,
so a cluster domain resolves **only for tailnet members** and is never published to
public DNS.

## Purpose

```
tailnet client ──query svc.example.com──▶ Tailscale (MagicDNS)
    └─ Split DNS: example.com ──forward──▶ in-cluster resolver device
           └─ answers with the ingress gateway tailnet IP (100.x)
                  └─ client routes to it over the tailnet
```

Two things this buys you:

- **Internal-only names.** The zone is forwarded to a tailnet-only nameserver. Nothing is
  published to public DNS, so internal service IPs never leak into a public zone.
- **It resolves at all.** If your tailnet runs MagicDNS with *Override local DNS* on,
  the zone will not resolve on-tailnet without a Split DNS entry — MagicDNS is the
  resolver, and it does not know about your cluster.

The resolver's tailnet IP is **discovered**, not configured. The component reads it from
the Tailscale device whose hostname is `dns_device_hostname`, which is the hostname the
Tailscale Kubernetes operator registers from the resolver Service's
`tailscale.com/hostname` annotation. Rescheduling the resolver does not require a var
change.

## Apply order (human-gated)

1. Deploy the in-cluster resolver (PowerDNS, CoreDNS/k8s-gateway, whatever answers the
   zone) with a `LoadBalancer` Service of `loadBalancerClass: tailscale` and a
   `tailscale.com/hostname` annotation.
2. Confirm the Tailscale operator registered the device and it is online.
3. `atmos terraform apply tailscale-dns -s <stack>`

The `tailscale_device` data source waits 60s for the device. If the resolver is not up
yet the apply **fails** rather than writing a Split DNS entry pointing at nothing.

## Required provider scopes

The Tailscale provider authenticates with an **OAuth client** read from the environment:

| Variable | Value |
|---|---|
| `TAILSCALE_OAUTH_CLIENT_ID` | OAuth client ID |
| `TAILSCALE_OAUTH_CLIENT_SECRET` | OAuth client secret |

The client needs exactly two scopes — nothing more:

| Scope | Access | Used for |
|---|---|---|
| `dns` | write | `tailscale_dns_split_nameservers` — creating/updating the Split DNS entry |
| `devices:core` | read | `tailscale_device` data source — discovering the resolver's tailnet IP |

Do not reuse a scope-`all` client here. This component never needs ACL access, key
management, or device *write*; a client limited to `dns` + `devices:core:read` turns a
credential leak into a DNS-scoped incident rather than a whole-tailnet one. Verify what
you actually provisioned rather than trusting the console UI:

```
GET /api/v2/tailnet/-/keys?all=true
```

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `dns_zone` | `string` | — | **yes** | Zone forwarded to the in-cluster resolver over the tailnet, e.g. `example.com`. Validated to reject a trailing dot (Tailscale Split DNS expects a bare domain) and to reject empty. |
| `dns_device_hostname` | `string` | — | **yes** | Tailscale device hostname of the in-cluster resolver. Must match the `tailscale.com/hostname` annotation on the resolver's Service. The device must already exist. |

Neither input is defaulted — both are deployment-specific, and a wrong default here would
silently point a real zone at the wrong nameserver.

## Outputs

| Name | Description |
|---|---|
| `dns_zone` | The zone actually registered as a Split DNS entry (read back from the resource). |
| `resolver_tailnet_ips` | All tailnet IPs of the discovered resolver device. The first is the one the Split DNS entry uses. |
| `resolver_device_hostname` | Tailscale device hostname of the in-cluster resolver. |

## Example Atmos catalog stanza

`stacks/catalog/terraform/tailscale-dns.yaml` — provider credentials come from a declared
1Password secret store (`stores.op` in `atmos.yaml`), never from committed values:

```yaml
components:
  terraform:
    tailscale-dns:
      metadata:
        component: tailscale-dns
        type: real
      vars:
        dns_zone: example.com
        # Must match tailscale.com/hostname on the in-cluster resolver Service.
        dns_device_hostname: cluster-dns

      # HUMAN-GATED: create a Tailscale OAuth client with ONLY the `dns` (write)
      # and `devices:core:read` scopes and store it in 1Password. Declaring the
      # secrets (rather than `!exec op read ...`) means `atmos secret validate`
      # catches a renamed item or mislabelled field before anything applies —
      # a dangling reference otherwise surfaces only as a mid-apply failure.
      secrets:
        vars:
          TAILSCALE_OAUTH_CLIENT_ID:
            description: "Tailscale OAuth client ID for Split DNS — scopes dns:write + devices:core:read"
            store: op
            reference: "op://<vault>/<item>/client_id"
            required: true
          TAILSCALE_OAUTH_CLIENT_SECRET:
            description: "Tailscale OAuth client secret paired with TAILSCALE_OAUTH_CLIENT_ID"
            store: op
            reference: "op://<vault>/<item>/client_secret"
            required: true
      env:
        TAILSCALE_OAUTH_CLIENT_ID: !secret TAILSCALE_OAUTH_CLIENT_ID
        TAILSCALE_OAUTH_CLIENT_SECRET: !secret TAILSCALE_OAUTH_CLIENT_SECRET
```

> **Field labels are not standardised.** 1Password item field labels are free-form, and
> hyphenated (`client-id`) vs underscored (`client_id`) labels on two different items is a
> real and easily-missed failure. Run `atmos secret validate` — it turns that into a
> pre-flight error instead of a mid-apply one.

## Vendoring with Atmos

`vendor.yaml` in the consuming repo:

```yaml
apiVersion: atmos/v1
kind: AtmosVendorConfig
metadata:
  name: infra-components
spec:
  sources:
    - component: tailscale-dns
      source: "github.com/fyrsmithlabs/terraform-tailscale-dns.git///?ref={{.Version}}"
      version: v0.1.0
      targets:
        - "components/terraform/tailscale-dns"
      included_paths:
        - "**/*.tf"
        - "**/README.md"
```

Then `atmos vendor pull`.

## License

MIT — see [LICENSE](LICENSE).
