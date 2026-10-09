# 0006. The GPU is found by vendor and device class, never by PCI address

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

The R9700 is at `0000:05:00.0` today. A reinstall or a hardware change in a few years will move it. TJ asked that nothing depend on numbers like that.

## Decision

`gpu_worker` reads the host's PCI devices with the provider's `proxmox_hardware_pci` data source, filtered by vendor and class through its `filters` block (AMD, display controller by default; both are inputs, matched by prefix). From the match it builds a `proxmox_hardware_mapping_pci` (address, IOMMU group, and `vendor:device` and subsystem IDs with the data source's `0x` prefixes removed). The VM attaches the GPU by mapping name. The module fails at plan time unless exactly one device matches. An optional `pci_address` input picks one when several do.

## Evidence

- `data.proxmox_hardware_pci` has existed since bpg v0.103.0. It filters by `vendor_id`, `class`, `device_id` and `id`, and returns the address and the IOMMU group.
- A raw `hostpci.id` needs root password authentication and does not work with an API token. A `mapping` works with a token.
- On 2026-10-09 the GPU was alone in IOMMU group 61, and its audio function was in group 62.

## Alternatives rejected

- Hard-coding the address in tfvars: breaks on any hardware change.
- An external data source that SSHes to `lspci`: unnecessary once the provider has a data source.

## Consequences

- PCI vendor ID `1002` (AMD) and class `03` are vendor-level constants, not slot-level ones. They are inputs with defaults.
- Each cluster creates its own named mapping to the same device. Proxmox refuses to start a second VM claiming a device that is in use, so `test` and `stable` cannot both run a GPU node at once.
