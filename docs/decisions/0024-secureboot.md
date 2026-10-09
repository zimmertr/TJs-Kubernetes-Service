# 0024. Every node boots with UEFI SecureBoot

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ
- Issues and PRs: the TKS v2 PR

## Context

[0016](0016-q35-uefi-everywhere.md) gave every node UEFI with an EFI disk that has no keys pre-enrolled. The image was the plain `nocloud` image, so the Talos console reported SecureBoot as disabled.

## Decision

- `modules/talos_image` downloads Image Factory's `disk_image_secureboot` (qcow2) and outputs `installer_secureboot` as the installer image for upgrades.
- The EFI disk keeps `type = "4m"` and `pre_enrolled_keys = false`, so UEFI boots in setup mode and the image enrolls its own keys.
- There is no switch to turn it off, and no TPM. A TPM is only needed for TPM-bound disk encryption, which TKS doesn't configure.

## Evidence

- 2026-10-09: Talos v1.14.0 and later write `loader/keys/auto/{PK,KEK,db}.auth` to SecureBoot disk images and set `secure-boot-enroll if-safe`, so systemd-boot enrolls the keys on first boot inside a VM (siderolabs/talos commit b31d93e0d). The v1.14.2 `nocloud-amd64-secureboot.qcow2` contains both.
- `talos_image_factory_urls` in terraform-provider-talos v0.12.0 returns `disk_image_secureboot` and `installer_secureboot` alongside the plain URLs.
- Validated on `test` (T23).

## Alternatives rejected

- Pre-enrolled Microsoft keys: the Talos UKI isn't signed by Microsoft, so it wouldn't boot.
- A switch for SecureBoot: it would only exist to turn off a protection that costs nothing.

## Consequences

- Switching an existing node to the SecureBoot installer in place upgrades it, but it keeps booting without SecureBoot (seen on `test`, 2026-10-09). Talos needs a fresh install, so turning SecureBoot on for an existing cluster means rebuilding it.
- The kernel runs in lockdown mode, which restricts debugfs.
- Only Sidero Labs' keys are enrolled, so OVMF probably won't run a passed-through GPU's option ROM. That means no pre-boot display on the GPU. The Linux driver is unaffected. To be confirmed in T28.
