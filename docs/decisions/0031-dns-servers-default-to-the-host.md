# 0031. Nodes use the Proxmox host's resolvers unless `network.dns_servers` is set

- Status: Accepted
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #106

## Context

`network.dns_servers` was required. Nodes get static IPs through cloud-init, so no DHCP server tells them which resolver to use, and something has to.

## Decision

`network.dns_servers` is optional. When it is set, the node module writes it to the VM's cloud-init `dns` block. When it is not, the module omits the block, and Proxmox fills in the nameservers from its host's `/etc/resolv.conf`.

## Evidence

- 2026-10-10: `get_dns_conf` in Proxmox's `PVE/QemuServer/Cloudinit.pm` (qemu-server, `HEAD`) falls back to `dns1`–`dns3` from the host's `resolv.conf` when the VM has no `nameserver`. An empty list never reaches the VM, so Talos's own defaults (1.1.1.1 and 8.8.8.8) are never used.
- `modules/node/tests/node.tftest.hcl` covers both cases.

## Alternatives rejected

- Default to Talos's resolvers by setting 1.1.1.1 and 8.8.8.8 explicitly. Works wherever outbound DNS is allowed, but ignores local DNS that the hypervisor already uses.
- Default to `network.gateway`. Assumes every router runs a DNS forwarder.

## Consequences

A cluster can be built without choosing a resolver. The host's resolver must be reachable from the node network, which is usually but not always true when nodes are on a different VLAN from the host. Existing tfvars that set `dns_servers` are unchanged.
