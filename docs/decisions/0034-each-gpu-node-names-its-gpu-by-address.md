# 0034. Each GPU node names its GPU by PCI address in the tfvars, and gets a mapping of its own

- Status: Accepted. Supersedes 0006
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #89, #108

## Context

0006 found the GPU by PCI vendor and class, so that nothing depended on an address. That only works when the host has one matching card. Two identical cards, which is the common case for more than one GPU, report the same vendor, device and subsystem IDs, so a model ID can't say which card a node gets. The other identifiers that tell identical cards apart either aren't reported by the Proxmox API (the physical slot, the optional PCIe Device Serial Number) or change along with the address (the IOMMU group).

## Decision

Each entry in `gpu_workers.nodes` sets `pci_address`, as `lspci` shows it. The `0000:` domain is optional. TKS reads the device at that address from `proxmox_hardware_pci` for the IDs and IOMMU group, and creates a `proxmox_hardware_mapping_pci` named `<cluster>-<hostname>-gpu` that holds only that card. The mapping's comment carries the device name Proxmox reports.

The plan fails when:
- an address is malformed
- two nodes name the same card
- nothing is at an address
- the device has no IOMMU group

The address is assumed to stay put. When a card moves, its new address goes in the tfvars and is applied.

## Evidence

- On 2026-10-10 `earth` showed the R9700 at `05:00.0` as `[1002:7551]`, subsystem `[1849:5413]` (ASRock).
- Proxmox's own resource mappings work the same way: a name for an address, updated in one place after a hardware change.
- `modules/pci_device/tests` tells two identical cards apart by address. `modules/gpu_worker/tests` checks that each node gets a mapping holding one card. `tests/cluster.tftest.hcl` rejects two nodes on one card, including one written with and one without the domain.

## Alternatives rejected

- Vendor and class (0006): can't tell identical cards apart.
- A model ID per node, with matching cards given out in address order: identical cards could swap nodes after a hardware change, and the tfvars wouldn't say which card a node has.
- One mapping holding every card, with Proxmox choosing a free one at start: nothing ties a node to a card.

## Consequences

- Several GPU nodes are supported, one card each, on the Proxmox node TKS deploys to.
- If a different device ends up at an address after a hardware change, the mapping's comment changes in the plan, and that is the only warning. Requiring a display-controller class would reject datacenter cards that report themselves as processing accelerators.
- Mediated devices (vGPU, MxGPU), several GPUs in one node, and GPUs on other Proxmox hosts aren't supported.
