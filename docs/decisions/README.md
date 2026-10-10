# Decision records

One file for each design decision: what was decided, when, who decided, and the evidence that settled it. `CLAUDE.md` says what to do today, and a record keeps why.

## Write a record

- Copy [`0000-template.md`](0000-template.md) to `NNNN-slug.md` with the next free number. Numbers have four digits and are never reused.
- The title is the decision, as one sentence.
- Date every measurement.
- Add a row to the index below in the same PR.

## Supersede a record

The new record says `Supersedes NNNN` in its status line. The old record changes its status line to `Superseded by NNNN` and nothing else.

## Index

| Record | Decision | Date | Status |
|---|---|---|---|
| [0001](0001-gpu-on-a-talos-worker.md) | GPU workloads run on a dedicated Talos worker node, not on a standalone VM | 2026-10-09 | Accepted |
| [0002](0002-gpu-worker-module.md) | The GPU worker is an optional, GPU-specific module, off by default | 2026-10-09 | Accepted |
| [0003](0003-v2-breaking-rebuild.md) | v2 is a breaking rewrite, and clusters are rebuilt rather than migrated | 2026-10-09 | Accepted |
| [0004](0004-ready-hypervisor.md) | TKS assumes a ready hypervisor, and host configuration stays out of it | 2026-10-09 | Accepted |
| [0005](0005-bootstrap-root-for-terraform-user.md) | An optional `bootstrap/` root module creates the Terraform user, and every cluster shares it | 2026-10-09 | Superseded by 0026 |
| [0006](0006-gpu-found-by-class.md) | The GPU is found by vendor and device class, never by PCI address | 2026-10-09 | Accepted |
| [0007](0007-local-state-default-hcp-opt-in.md) | Local state stays the default, and HCP Terraform is opt-in through a gitignored override file | 2026-10-09 | Accepted |
| [0008](0008-static-ips-via-cloud-init.md) | Nodes get static IPs through cloud-init, not DHCP reservations | 2026-10-09 | Accepted |
| [0009](0009-nodes-as-maps.md) | Nodes are maps keyed by hostname, with defaults for each pool | 2026-10-09 | Accepted |
| [0010](0010-qcow2-images-no-ssh.md) | Talos images are downloaded as `qcow2` and imported by the provider, without SSH | 2026-10-09 | Accepted |
| [0011](0011-in-place-upgrades-by-terraform.md) | Version bumps upgrade nodes in place through `talos_machine` and `talos_cluster`, and never replace VMs | 2026-10-09 | Accepted |
| [0012](0012-renovate-automerge.md) | Renovate auto-merges everything below a major, except Kubernetes minors, and comments on Talos and Kubernetes compatibility | 2026-10-09 | Accepted |
| [0013](0013-ci-and-semver-releases.md) | Every pull request runs format, validate, lint, scan, test and workflow lint, and releases are cut from PR titles | 2026-10-09 | Accepted |
| [0014](0014-right-size-from-measured-usage.md) | `stable` is right-sized from measured usage to make room for a 192 GB GPU node | 2026-10-09 | Accepted |
| [0015](0015-gpu-reset-risk-accepted.md) | The GPU reset risk is accepted and tested on first attach, rather than in a separate spike | 2026-10-09 | Accepted |
| [0016](0016-q35-uefi-everywhere.md) | Every node uses the q35 machine type with UEFI firmware | 2026-10-09 | Accepted |
| [0017](0017-gpu-taint-extended-resource-toleration.md) | GPU nodes carry the taint `amd.com/gpu:NoSchedule`, and pods that request the GPU tolerate it automatically | 2026-10-09 | Accepted |
| [0018](0018-docs-for-users.md) | The docs describe TKS for its users, and maintainer runbooks stay out of the repository | 2026-10-09 | Superseded by 0020 |
| [0019](0019-a-handful-of-prs.md) | v2 lands as a handful of pull requests into `main`, after `v1.0.0` is tagged | 2026-10-09 | Accepted |
| [0020](0020-readme-is-tjs.md) | The README stays in TJ's own voice and remains the main guide, and `docs/` holds the reference pages | 2026-10-09 | Accepted |
| [0021](0021-compat-check-reads-talos-support-matrix.md) | The compatibility check reads the Kubernetes range from Talos's source, not from `talosctl gen config` | 2026-10-09 | Accepted |
| [0022](0022-secrets-ignore-config-version.md) | The machine secrets ignore later `talos_version` changes instead of refusing to be destroyed | 2026-10-09 | Accepted |
| [0023](0023-manage-nodes-returns.md) | A slimmed-down `bin/manage_nodes` returns for node removal and rolling reboots | 2026-10-09 | Accepted |
| [0024](0024-secureboot.md) | Every node boots with UEFI SecureBoot | 2026-10-09 | Accepted |
| [0025](0025-destroy-does-not-reset.md) | Destroying a node only deletes its VM, and `manage_nodes remove` takes a single node out of the cluster | 2026-10-09 | Accepted |
| [0026](0026-bootstrap-creates-integration-users.md) | `bootstrap/` creates every Proxmox user from a `users` map in `vars/bootstrap.tfvars`, including the one TKS runs as | 2026-10-09 | Accepted |
| [0027](0027-optional-external-cloud-provider.md) | An optional switch hands nodes to an external cloud controller manager, and `manage_nodes remove` stays for control planes | 2026-10-10 | Accepted |
| [0028](0028-manage-nodes-reregister.md) | `manage_nodes reregister` registers existing nodes again after the external cloud provider is turned on | 2026-10-10 | Superseded by 0029 |
| [0029](0029-reregister-reboots-the-node.md) | `manage_nodes reregister` reboots each node after deleting it, so it comes back on its new pod CIDR | 2026-10-10 | Accepted |
| [0030](0030-readme-neutral-voice.md) | The README is written in neutral, professional prose and doesn't advertise TJ's other repositories | 2026-10-10 | Accepted |
| [0031](0031-dns-servers-default-to-the-host.md) | Nodes use the Proxmox host's resolvers unless `network.dns_servers` is set | 2026-10-10 | Accepted |
