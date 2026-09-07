# Changelog

All notable changes to this component are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-09-06

### Added

- Initial release.
- `tailscale_dns_split_nameservers` entry forwarding a cluster zone to an in-cluster
  resolver, resolvable only by tailnet members.
- Resolver tailnet IP is discovered from the Tailscale device matching
  `dns_device_hostname` (60s wait) rather than being configured, so rescheduling the
  resolver needs no var change.
- Validation rejecting a trailing dot on `dns_zone`, and rejecting empty values for both
  inputs.
- Outputs for the registered zone, the resolver's tailnet IPs, and its device hostname.
- README covering apply order, the exact provider scopes required
  (`dns` write + `devices:core` read), and an Atmos catalog stanza using declared
  `op://` secrets.

### Changed

- `dns_zone` and `dns_device_hostname` no longer carry defaults. Both are
  deployment-specific, and the in-repo defaults would have silently pointed a real zone at
  the wrong nameserver in any other deployment. Consuming stacks must set both explicitly.

[Unreleased]: https://github.com/fyrsmithlabs/terraform-tailscale-dns/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/fyrsmithlabs/terraform-tailscale-dns/releases/tag/v0.1.0
