# 0033. The PCI device is chosen in its own module, so the choice can be tested

- Status: Accepted
- Date: 2026-10-10
- Decider: Claude, for T27
- Issues and PRs: #89

## Context

`data.proxmox_hardware_pci` returns its devices as a list-nested attribute. In Terraform 1.16.5, `terraform test` cannot mock one: `fillAttribute` in `internal/moduletest/mocking/fill.go` turns a list-nested attribute into an empty list, and anything else fails with `incompatible types; expected object type`. That applies to `mock_data` and `override_data` alike, checked on 2026-10-10. The logic that chooses the GPU (exactly one match, `pci_address`, the IOMMU group, IDs without `0x`) would otherwise have no test.

## Decision

`modules/pci_device` takes the device list as a plain variable, chooses one device, and outputs it as a mapping entry. Output preconditions fail the plan when the number of matches isn't one, and when the device has no IOMMU group. `modules/gpu_worker` keeps the data source and passes its devices in. The mapping spells out each attribute of the entry, because the provider rejects an entry that is unknown as a whole during validation, even under `count = 0`.

## Evidence

- `modules/pci_device/tests` covers one match, two matches, a chosen address, an address that matches nothing, no match, and no IOMMU group.
- `modules/gpu_worker/tests` replaces `module.device` with `override_module` and checks the mapping and the PCIe attachment.

## Alternatives rejected

- A test-only `devices` input on `gpu_worker`: production code that only exists for tests.
- No tests for the selection: a behaviour change without a test is incomplete in this project.

## Consequences

If a later Terraform can mock list-nested attributes, the module can be folded back into `gpu_worker`, but nothing requires it.
