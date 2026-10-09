# 0016. Every node uses the q35 machine type with UEFI firmware

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

v1 VMs use Proxmox's defaults: the `i440fx` machine type (a PCI-only chipset) and SeaBIOS. A passed-through GPU wants a native PCIe topology (`hostpci` `pcie = true` requires `q35`), and a 32 GB card needs a large 64-bit memory window, which UEFI (OVMF) maps more cleanly.

## Decision

Every TKS node, GPU or not, uses `machine = "q35"` and `bios = "ovmf"` with a 4 MB EFI disk (`efi_disk.type = "4m"`) on the node's datastore. Secure Boot keys are not pre-enrolled.

## Evidence

The bpg provider documents that `pcie` on `hostpci` requires `q35`. Talos `nocloud` images boot under both BIOS and UEFI.

## Alternatives rejected

- `q35` and UEFI on the GPU node only: two hardware profiles for no benefit, since v2 rebuilds every node anyway.

## Consequences

- Each VM gains a small EFI-vars disk.
