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

Every outcome leads to the same architecture. Any VM-based design shares the reset behavior, and the only design that avoids it (sharing the host's driver into an LXC container) excludes Talos and Kubernetes. So a spike could only choose a mitigation, and the first attach answers that.

## Alternatives rejected

- A throwaway VM spike before the refactor: it could not change the direction.

## Consequences

- Known limitation until proven otherwise: rebooting the GPU node, which includes every Talos upgrade, may need a host reboot.
- Running ROCm inside a VM has historically depended on PCIe atomics. The first-attach task checks this as well.
