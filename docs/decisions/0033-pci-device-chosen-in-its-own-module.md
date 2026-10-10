# 0033. The PCI device is looked up in its own module, so the lookup can be tested

- Status: Accepted
- Date: 2026-10-10
- Decider: Claude, for T27
- Issues and PRs: #89

## Context

`data.proxmox_hardware_pci` returns its devices as a list-nested attribute. In Terraform 1.16.5, `terraform test` cannot mock one: `fillAttribute` in `internal/moduletest/mocking/fill.go` turns a list-nested attribute into an empty list, and anything else fails with `incompatible types; expected object type`. That applies to `mock_data` and `override_data` alike, checked on 2026-10-10. The logic that finds a GPU by its address, checks its IOMMU group and strips the `0x` from its IDs would otherwise have no test.

## Decision

`modules/pci_device` takes the device list and an address as plain variables, and outputs the device at that address as a mapping entry, plus a label of its model ID and name. Output preconditions fail the plan when nothing is at the address, and when the device has no IOMMU group. `modules/gpu_worker` keeps the data source and calls the module once per GPU node. The mapping spells out each attribute of the entry, because the provider rejects an entry that is unknown as a whole during validation, even under `count = 0`. [0034](0034-each-gpu-node-names-its-gpu-by-address.md) describes how a GPU is named.

## Evidence

- `modules/pci_device/tests` covers the entry, telling identical cards apart, an address with no device, and no IOMMU group.
- `modules/gpu_worker/tests` replaces `module.device` with `override_module` and checks the mappings and the PCIe attachments.

## Alternatives rejected

- A test-only `devices` input on `gpu_worker`: production code that only exists for tests.
- No tests for the selection: a behaviour change without a test is incomplete in this project.

## Consequences

If a later Terraform can mock list-nested attributes, the module can be folded back into `gpu_worker`, but nothing requires it.
