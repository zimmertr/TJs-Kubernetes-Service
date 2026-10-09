# PRD: TKS v2 and the GPU worker

- Status: Draft for review
- Date: 2026-10-09
- Owner: TJ
- Task plan: [`PLAN.md`](PLAN.md)
- Decisions: [`decisions/`](decisions/README.md)

## 1. Project overview

TJ's Kubernetes Service (TKS) builds Talos Linux Kubernetes clusters on Proxmox with Terraform. This project does two things.

1. **TKS v2.** A one-time, breaking rewrite that brings TKS in line with current practice: modules, typed node maps, static addressing, in-place upgrades by Terraform, CI, tests, automated releases and documentation. Existing clusters are rebuilt from it, not migrated ([0003](decisions/0003-v2-breaking-rebuild.md)).
2. **The GPU worker.** An optional module that adds a Talos worker VM with a host GPU passed through, so GPU workloads run as ordinary Kubernetes pods ([0001](decisions/0001-gpu-on-a-talos-worker.md), [0002](decisions/0002-gpu-worker-module.md)). The first GPU is an AMD Radeon AI PRO R9700 (Navi 48, RDNA4, 32 GB) in the Proxmox host `earth`.

The goal behind both is local AI: coding LLMs first, then image generation and other models, served to devices on the LAN (laptops, Claude Code) and to workloads in the cluster. The AI workloads themselves are **out of scope** here. They are planned separately in Kubernetes-Manifests (section 7, phase 4).

### Non-goals

- Configuring the Proxmox host (APT, IOMMU, ZFS, storage settings, drivers, mail, snapshots). TKS assumes a ready hypervisor ([0004](decisions/0004-ready-hypervisor.md)). Host settings live in Bootstrap-Proxmox or are made by hand.
- Migrating v1 state. v1 users pin `v1.0.0`.
- Plans or applies in CI against real infrastructure ([0013](decisions/0013-ci-and-semver-releases.md)).
- DNS records, observability, and any AI workload.

## 2. Core requirements

### Functional

| ID | Requirement |
|---|---|
| R1 | One Terraform root builds one cluster per workspace (`stable` and `test` today), from a tfvars file. |
| R2 | Nodes are declared as maps keyed by hostname, with pool defaults and per-node overrides. Any node can be added or removed on its own ([0009](decisions/0009-nodes-as-maps.md)). |
| R3 | Nodes get static IPs, gateway and DNS through cloud-init, and their hostname through their Talos config. No DHCP reservations are needed ([0008](decisions/0008-static-ips-via-cloud-init.md)). |
| R4 | Talos images come from the Image Factory with per-pool extension lists, built by the Talos provider and imported as `qcow2` by the Proxmox provider, without SSH ([0010](decisions/0010-qcow2-images-no-ssh.md)). |
| R5 | Changing the Talos or Kubernetes version never replaces a VM. `terraform apply` upgrades nodes in place, one at a time with drains (`talos_machine`), and upgrades Kubernetes with health gates (`talos_cluster`) ([0011](decisions/0011-in-place-upgrades-by-terraform.md)). |
| R6 | An optional GPU worker pool attaches a host GPU found by vendor and device class, never by PCI address ([0006](decisions/0006-gpu-found-by-class.md)). It is off by default and adds zero resources when off. |
| R7 | GPU nodes are tainted `amd.com/gpu:NoSchedule` and labeled `tks.io/pool=gpu`. Pods requesting `amd.com/gpu` tolerate the taint automatically ([0017](decisions/0017-gpu-taint-extended-resource-toleration.md)). |
| R8 | An optional `bootstrap/` root creates a least-privilege Proxmox role, user, ACL and API token, applied once and shared by every cluster ([0005](decisions/0005-bootstrap-root-for-terraform-user.md)). |
| R9 | State is local by default. A gitignored override file can point workspaces at HCP Terraform with local execution ([0007](decisions/0007-local-state-default-hcp-opt-in.md)). |
| R10 | Removing a node resets it gracefully and removes it from Kubernetes, with no provisioner and no helper script. |
| R11 | The existing feature switches carry over: disabling Flannel and kube-proxy (for Cilium), exposing control-plane metrics, and kubelet serving-certificate rotation. |

### Non-functional

| ID | Requirement |
|---|---|
| N1 | Every PR runs `fmt`, `validate`, `tflint`, `trivy config`, `terraform test` (mocked providers), `actionlint`, and Talos config validation. All are required checks, and all can be reproduced with Make targets ([0013](decisions/0013-ci-and-semver-releases.md)). |
| N2 | PR titles are conventional commits. Squash merges to `main` cut semver tags and GitHub Releases automatically. |
| N3 | Renovate keeps every dependency current. Everything below a major auto-merges on green checks, except Kubernetes minors. A check comments on every Talos or Kubernetes version PR with their compatibility, and fails incompatible pairs ([0012](decisions/0012-renovate-automerge.md)). |
| N4 | GitHub Actions are SHA-pinned with least-privilege tokens. Secret scanning and push protection are on. |
| N5 | Docs are written for TKS users. The README is an index, the prose lives in `docs/`, and nothing is a maintainer runbook ([0018](decisions/0018-docs-for-users.md)). |
| N6 | No backwards-compatibility code. The providers' current resources are used: `proxmox_*` short names where they exist, and Talos's current config documents. |
| N7 | By convention, TJ merges every human or agent PR himself. The ruleset can't enforce an approval, because GitHub forbids self-approval and Renovate must auto-merge. Nothing is applied to real infrastructure without TJ's approval for that run. |

## 3. Core features

1. **Typed, validated configuration.** Objects for `proxmox`, `network`, `cluster`, `controlplane`, `workers` and `gpu_workers`, with `optional()` defaults. Validation rejects IPs outside the CIDR, duplicate IPs or VMIDs, and a VIP that collides with a node.
2. **Two Talos versions.** `talos_version` is the installed OS, which Renovate bumps. `talos_config_version` is the provider's config contract, pinned when a cluster is created. Lowering the contract would regenerate the cluster's PKI, so `talos_machine_secrets` has `prevent_destroy`.
3. **Static addressing and hostnames.** The `initialization` block writes the cloud-init network config, and a `HostnameConfig` patch names each node after its map key. TKS no longer chooses MACs.
4. **Image module.** `talos_image_factory_schematic` and `talos_image_factory_urls` produce a `qcow2` URL and an installer image for each pool. `proxmox_download_file` imports the image under a name that includes the cluster and the pool. The GPU pool adds `siderolabs/amdgpu`.
5. **Modern VM profile.** `q35`, UEFI (OVMF) with a 4 MB EFI disk, the `host` CPU type, fixed memory, the guest agent, and thin disks on FlashPool ([0016](decisions/0016-q35-uefi-everywhere.md)).
6. **In-place lifecycle.** `talos_machine` for each node: applies the config, upgrades the OS when the installer image changes (draining first), and resets the node on destroy. `talos_cluster` performs health-gated Kubernetes upgrades. Applies run with `-parallelism=1` (set in `config.env`), so upgrades roll one node at a time, workers before control planes.
7. **GPU worker module.** Discovers the device with `data.proxmox_hardware_pci` (AMD, display class by default). Fails at plan time unless exactly one device matches or `pci_address` selects one. Creates a per-cluster `proxmox_hardware_mapping_pci`, attaches it with `pcie = true`, and applies the taint and label.
8. **Scheduling support.** Every cluster enables the `ExtendedResourceToleration` admission plugin.
9. **Optional `bootstrap/` root.** Role, user, ACL and token, with a documented privilege list.
10. **Repository foundations.** CI, conventional-commit checks, automated releases, Renovate with the compatibility check, docs, ADRs and CLAUDE.md.

## 4. Core components

| Component | Path | Responsibility |
|---|---|---|
| Root module | `/` | Wires the cluster: providers, Talos machine secrets, bootstrap, `talos_cluster`, image modules, node pools, and the kubeconfig, talosconfig and node outputs. |
| `talos_image` | `modules/talos_image/` | Image Factory schematic and URLs, plus `proxmox_download_file`. Outputs the image file ID, schematic ID and installer image. |
| `node` | `modules/node/` | One pool of Talos VMs (`for_each`): VM, cloud-init network, machine config, `talos_machine`, and optional PCI devices. Used for control planes and workers. |
| `gpu_worker` | `modules/gpu_worker/` | GPU discovery, the PCI mapping, its own `talos_image` with `amdgpu`, and a `node` pool with the device attached, the taint and the label. |
| `bootstrap/` | `bootstrap/` | A separate, optional root: Proxmox role, user, ACL and API token. |
| Talos patches | `configs/` | Config documents: global, control plane (`Layer2VIPConfig`), the Flannel switch, metrics exposure, and the GPU node's taint and label. |
| Tests | `tests/`, `modules/*/tests/` | `terraform test` suites with `mock_provider`. |
| CI | `.github/workflows/` | `pr.yml` (checks), `pr-title.yml` (title and predicted version), `release.yml` (tag and release on merge), `compat.yml` (Talos/Kubernetes compatibility comment and check). |
| Renovate | `.github/renovate.json` | Dependency updates and auto-merge rules. |
| Docs | `README.md`, `docs/`, `CLAUDE.md` | User docs, ADRs and agent guidance. |

`bin/` is removed. Its jobs are provider features now, or unnecessary.

External systems: the Proxmox VE 9.2 API on `earth`, the Talos Image Factory, HCP Terraform (TJ only), GitHub (Actions, Releases, Issues, Projects) and Renovate.

## 5. App and user flow

### Build a cluster (any TKS user)

1. Meet the Requirements table: Proxmox 9.x, an API token with the documented privileges, the `Import` content type on the image datastore, and a DHCP range that excludes the node IPs. For GPU nodes, also an IOMMU-capable host with the GPU alone in its IOMMU group.
2. Optional: apply `bootstrap/` once with root credentials, and put its token in `config.env`.
3. Copy `vars/config.env.example`, which also sets `-parallelism=1` for applies, and an example tfvars. Fill in the network, the cluster and the node maps, with `talos_config_version` equal to `talos_version` at creation.
4. `source vars/config.env`, `terraform init`, `terraform workspace new <cluster>`, then `terraform apply -var-file=vars/<cluster>.tfvars`.
5. Export the kubeconfig and talosconfig from the outputs.

### Day-two operations

- **Scale:** add or remove a line in a node map, then `apply`. A removed node is drained, reset and dropped from Kubernetes.
- **Upgrade:** a Renovate PR merges (Kubernetes minors and majors wait for review, and the compatibility comment says whether the pair is supported), or a user edits the versions. Then `apply`. Workers, then control planes, upgrade one at a time. Kubernetes is upgraded by `talos_cluster`.
- **Host reboot:** reboot by hand. Proxmox shuts guests down through the guest agent, and Talos shuts down gracefully. T23 verifies that nodes return schedulable on their own.

### GPU

1. Add a node to `gpu_workers.nodes` in the tfvars, then `apply`. The module finds the GPU, maps it, and boots a Talos node with `amdgpu` loaded.
2. Kubernetes-Manifests installs the AMD device plugin or GPU Operator (with a toleration for the GPU taint), and the node advertises `amd.com/gpu: 1`.
3. A pod requesting `amd.com/gpu: 1` is scheduled onto the node and tolerates the taint automatically.
4. Moving the GPU between clusters means removing the GPU node from one workspace, then adding it in the other.

### Consumers (phase 4, for context)

Laptops, Claude Code and in-cluster workloads call one OpenAI-compatible endpoint, a Kubernetes Service exposed on the LAN. One inference server (the intended choice is llama-swap in front of llama.cpp) owns the GPU and swaps models on demand.

## 6. Tech stack

| Layer | Choice | Version target (2026-10-09) |
|---|---|---|
| Hypervisor | Proxmox VE | 9.2 (kernel 7.0) |
| IaC | Terraform | >= 1.16 (1.16.5) |
| Proxmox provider | bpg/proxmox | ~> 0.116.0 |
| Talos provider | siderolabs/talos | ~> 0.12.0 (`talos_machine`, `talos_cluster` and Image Factory resources) |
| OS | Talos Linux | v1.14.2 (Linux 6.18) |
| Kubernetes | Kubernetes | v1.37.1 |
| GPU extension | `siderolabs/amdgpu` | matches Talos |
| State | Local, or HCP Terraform (local execution) | — |
| Lint and scan | tflint plus the Terraform ruleset, Trivy (`trivy config`), actionlint, `talosctl validate` | latest at implementation |
| Tests | `terraform test` with `mock_provider` | — |
| CI and release | GitHub Actions (SHA-pinned), conventional commits, automated semver | — |
| Dependencies | Renovate | — |
| Tracking | GitHub Issues in each repo, plus one GitHub Project | — |
| Phase 4 (intended) | AMD GPU Operator or device plugin, llama-swap with llama.cpp (Vulkan first, ROCm benchmarked), a 500 GB PVC on thin FlashPool (`proxmox-flashpool`) | — |

### Environment facts this plan relies on

Measured on 2026-10-09.

- `earth`: Xeon E5-2699 v4 (44 threads), 503 GB installed and **planned as 384 GB** (one DIMM is unreliable), single-node Proxmox cluster `sol-milkyway`.
- The GPU is at `05:00.0` (vendor `1002`, device `7551`), alone in IOMMU group 61, with its audio function in group 62. The host console uses the ASPEED BMC, so the host has no use for `amdgpu`.
- FlashPool is a mirror of two Samsung 970 PRO 1 TB drives, with about 205 GB actually allocated. Thin provisioning was enabled on 2026-10-09.
- Network: VLAN 40, `192.168.40.0/24`. `.1x` are control planes, `.2x` workers and `.3x` GPU nodes for `stable`, and `.5x`, `.6x` and `.7x` the same for `test`. VMIDs are `40` followed by the IP's last octet.

### Sizing ([0014](decisions/0014-right-size-from-measured-usage.md))

| Node | Cores | RAM | OS disk |
|---|---|---|---|
| `k8s-cp-1..3` (.11–.13 / 4011–4013) | 4 | 8 GB | 50 GB |
| `k8s-node-1..3` (.21–.23 / 4021–4023) | 6 | 24 GB | 50 GB |
| `k8s-node-gpu-1` (.31 / 4031) | 16 | 192 GB | 50 GB |
| `test-k8s-cp-1` (.51 / 4051) and `test-k8s-node-1` (.61 / 4061) | 4 | 4 GB | 10 GB |
| `test-k8s-node-gpu-1` (.71 / 4071) | 8 | 32 GB | 50 GB |

## 7. Implementation plan

The detailed, dependency-linked task list is [`PLAN.md`](PLAN.md). In summary:

| Phase | Lands as | Outcome |
|---|---|---|
| 0. Setup | Tag, issues, Project | `v1.0.0` pins v1. Every task is a GitHub issue on one board. |
| 1. Foundations | PR: CI, releases, Renovate base, docs skeleton | Every later PR is checked, versioned and documented. |
| 2. v2 refactor | PR: modules, node maps, static IPs, provider-driven upgrades, `bootstrap/`, version managers with the compatibility check, tests | `v2.0.0` released, then `test` and `stable` rebuilt. |
| 3. GPU worker | PR: `gpu_worker`, plus a Bootstrap-Proxmox cleanup | `v2.1.0`. GPU validated on `test`, then owned by `stable`. |
| 4. AI workloads | Kubernetes-Manifests (separate planning pass) | Device plugin, inference server, model storage, exposure. |

### Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| The R9700 doesn't reset cleanly on VM restart ([0015](decisions/0015-gpu-reset-risk-accepted.md)) | Medium | GPU-node reboots and upgrades need a host reboot | First-attach reset test (T28). Host-side mitigations (T29). Host reboots stay manual. |
| ROCm in a VM needs PCIe atomics the virtual topology lacks | Low–Medium | ROCm fails; Vulkan may still work | `q35` with `pcie = true`, tested in T28. llama.cpp's Vulkan backend as fallback. |
| `talos_machine` and `talos_cluster` are new (3 weeks), and `ignore_kubernetes_upgrade_drift` is experimental | Medium | An upgrade misbehaves | Exercised on `test` (T23.6–23.7) before `stable`. Every apply is TJ's to approve. |
| Static IPs through cloud-init fail, as TJ once believed | Low | Addressing redesign | Verified first on `test` (T23.4). DHCP reservations are the documented fallback. |
| A lowered `talos_config_version` regenerates the PKI | Low | The cluster is bricked | `prevent_destroy` on the secrets, a validation, and a test (T16). |
| GPU Operator with Talos's built-in driver is unproven | Medium | Phase 4 uses the plain device plugin | Decided in phase 4. TKS only guarantees `amdgpu` loads. |
| Thin FlashPool overcommits | Low | Writes fail on every FlashPool VM | Real usage is 21%. Nothing alerts on pool capacity, a known gap that's out of scope. |
| HCP free-tier terms change again | Low | State migration | Only the override file changes, and local state still works. |
| An auto-merged version bump is unsupported | Low | Failed upgrade at `apply` | The compatibility check blocks the merge. Kubernetes minors wait for review. |
| Memory pressure from pinned GPU VM memory | Low | The GPU VM fails to start | 296 GB committed of 384 GB, and the `test` GPU node only exists while `stable`'s doesn't. |
