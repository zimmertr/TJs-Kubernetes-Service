# 0015. The GPU reset risk is accepted and tested on first attach, rather than in a separate spike

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

Navi 48 cards (the RX 9070 XT, `1002:7550`) are reported to lack a reliable function-level reset. A VM restart can leave the card unusable until the host reboots. No reports were found for the R9700 (`1002:7551`). Advice conflicts on whether the host's `amdgpu` should bind the card first or never. A standalone spike was proposed, then dropped.

## Decision

There is no separate spike. The first GPU task attaches the card to `test-k8s-node-gpu-1` and runs stop/start and reboot cycles. If they fail, a conditional task adds a mitigation:
- first, a host driver setting in Bootstrap-Proxmox (let the host's `amdgpu` bind the card at boot, or a `softdep`)
- if that fails, a Proxmox hookscript that returns the card to the host's driver when the VM stops. Setting a hookscript needs root and snippets need SSH, so it cannot come from TKS's API token. It would be a Bootstrap-Proxmox or manual step.

No automation ever reboots the hypervisor. That stays a manual step.

## Evidence

First attach, T28 (#90), on 2026-10-10. The R9700 (`1002:7551`, subsystem `1849:5413`) on `earth` (Xeon E5-2699 v4) went to `test-k8s-node-gpu-1` on Talos 1.14.2 (kernel 6.18.54) through the mapping `test-gpu-4071`. Before that, the host's own `amdgpu` had bound the card at boot, and no `vfio-pci` binding or `softdep` was set.

- `amdgpu` initialized the card in the guest: 32 GB of VRAM, 64 compute units, and KFD added the device. `/dev/kfd` and `/dev/dri/renderD128` existed.
- ROCm 6.4 (`rocm/rocm-terminal`) listed `gfx1201`. A HIP kernel gave 0 mismatches over 1M elements.
- PCIe atomics: inside the guest, the GPU showed `AtomicOpsCtl: ReqEn+` (32- and 64-bit). 262,144 of 262,144 system-scope atomic adds to coherent host memory landed.
- Vulkan: Mesa 25.3.6 (Fedora 43) reported "AMD Radeon AI PRO R9700 (RADV GFX1201)", Vulkan 1.4. The Mesa 23.2 in `rocm/rocm-terminal` predates RDNA4 and could not initialize the card.
- Nine cycles, between 05:48 and 05:56 UTC: three in-guest `talosctl reboot`, three Proxmox stop then start, and three Proxmox reset.
  - Each one produced a new boot ID.
  - After each, the node was Ready in 35 to 86 seconds, `amdgpu` and KFD initialized again, and both device files were back.
  - No `amdgpu` errors were logged.
  - After the last cycle, the HIP and atomics test passed again.
- No host reboot was needed at any point, so the reset problem reported for the RX 9070 XT did not show up on this card.

Every outcome leads to the same architecture. Any VM-based design shares the reset behavior, and the only design that avoids it (sharing the host's driver into an LXC container) excludes Talos and Kubernetes. So a spike could only choose a mitigation, and the first attach answers that.

## Alternatives rejected

- A throwaway VM spike before the refactor: it could not change the direction.

## Consequences

- Known limitation until proven otherwise: rebooting the GPU node, which includes every Talos upgrade, may need a host reboot. On 2026-10-10 nine reboots, stops and resets of the R9700 needed none, so T29 (#91) has no mitigation to add.
- Running ROCm inside a VM has historically depended on PCIe atomics. The first-attach task checks this as well.
