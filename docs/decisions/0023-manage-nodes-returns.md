# 0023. A slimmed-down `bin/manage_nodes` returns for node removal and rolling reboots

- Status: Superseded by 0037
- Date: 2026-10-09
- Decider: TJ
- Issues and PRs: T23, the TKS v2 PR

## Context

[0011](0011-in-place-upgrades-by-terraform.md) removed `bin/`, expecting the providers to cover everything it did. Testing v2 on `test` found two gaps:

- Talos's reset on destroy leaves etcd, but the Kubernetes Node object stays. v1's `manage_nodes remove` ran `kubectl delete node`.
- A change to a VM's cores, memory or controller makes the Proxmox provider restart that VM at once. Terraform then moves straight on to the next VM, so every control plane can be down at the same time.

## Decision

- VMs set `reboot_after_update = false`.
- `bin/manage_nodes` has two commands, run by hand:
  - `remove NODE` deletes the Node object.
  - `reboot [NODE...]` drains each node, restarts its VM through the Proxmox API, waits for it to be Ready (and for etcd on a control plane), and uncordons it, one at a time with control planes first.
- It reads the cluster's `kubeconfig`, `talosconfig` and `nodes` outputs and the credentials in `vars/config.env`. It is not a provisioner.

## Evidence

- 2026-10-09: on `test`, a removed worker's Node object was still `NotReady` two minutes later.
- 2026-10-09: on `test`, changing the SCSI controller restarted both VMs back to back. With the new setting, a memory change waited, and `manage_nodes reboot` applied it one node at a time.
- A reboot from inside the guest keeps the same QEMU process, so pending Proxmox hardware changes only apply when Proxmox restarts the VM.

## Alternatives rejected

- A destroy-time provisioner running `kubectl delete node`: destroy provisioners can only read the resource being destroyed, so they can't easily get a kubeconfig.
- The Proxmox cloud controller manager, which deletes Node objects whose VMs are gone: it belongs in the cluster's GitOps config, and investigating it is a separate issue.

## Consequences

- Removing a node and changing node hardware each need a manual command after `apply`.
- `kubectl`, `talosctl`, `jq` and `curl` are needed on the machine running it.
