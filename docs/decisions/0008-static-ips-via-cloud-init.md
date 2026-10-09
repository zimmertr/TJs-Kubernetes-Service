# 0008. Nodes get static IPs through cloud-init, not DHCP reservations

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

v1 derives a MAC address and an IP for each node from prefixes plus a single digit, and relies on a hand-made DHCP reservation in OPNsense for each one. That caps each pool at nine nodes and puts a manual step outside Terraform before every apply. TJ had believed static addressing did not work.

## Decision

Each node's address, gateway and DNS servers are written by the VM resource's `initialization` block into a cloud-init network config, which the Talos `nocloud` image reads at boot. Each node's hostname is set in its own Talos machine config (a `HostnameConfig` document), because Proxmox's nocloud metadata carries no hostname that Talos reads. MAC addresses are no longer chosen by TKS. Terraform addresses nodes by IP, never by DNS name.

## Evidence

Static addressing through cloud-init is the approach Sidero documents for Talos on Proxmox. It has not yet been proven on TJ's network. Task T23 verifies it on `test` before anything else depends on it.

## Alternatives rejected

- Keep DHCP reservations: a manual step outside the source of truth.
- Support both: more module logic for a path nobody would choose. DHCP reservations remain the documented fallback if the verification fails.

## Consequences

- v1 got hostnames from DHCP reservations. Without the hostname patch, v2 nodes would come up as `talos-xxx`.
- DNS records for node names are a convenience for people, not a TKS requirement.
- The DHCP range on the VLAN must not overlap node IPs. TJ confirmed `192.168.40.3x` is free.
