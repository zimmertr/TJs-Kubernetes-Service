# 0011. Version bumps upgrade nodes in place through `talos_machine` and `talos_cluster`, and never replace VMs

- Status: Accepted. The guard on the machine secrets is amended by 0022
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

In v1, a VM's disk is cloned from the image of the current `talos_version`, so changing the version replaces every node. Renovate auto-merges version bumps ([0012](0012-renovate-automerge.md)). siderolabs/talos v0.12.0 (2026-09-21) added two resources:
- `talos_machine`: applies machine config; upgrades the OS in place when `image` changes, draining the node first; resets the node on destroy.
- `talos_cluster`: runs Talos's health-gated `upgrade-k8s` when `kubernetes_version` changes.

## Decision

- Each node is a `talos_machine`, with `image` set to its pool's installer image, `drain_on_upgrade = true`, `on_destroy = { reset = true, graceful = true }`, and `ignore_kubernetes_upgrade_drift = true`. The cluster has one `talos_cluster` that owns Kubernetes upgrades.
- There are two Talos versions:
  - `talos_version` is the installed OS. Renovate bumps it, and it drives the installer image.
  - `talos_config_version` is the provider's config-generation contract. It is pinned when a cluster is created and changed only deliberately.
- `talos_machine_secrets` has `prevent_destroy`. (Replaced by `ignore_changes`, see 0022.)
- Applies run one node at a time (`TF_CLI_ARGS_apply="-parallelism=1"` in `config.env`), so a rolling upgrade never takes down more than one node.
- VM disks import the image once. A changed image never replaces a VM.
- `bin/` is removed. Its upgrade, remove and reboot helpers are now provider features or unnecessary.

## Evidence

- The talos provider docs (v0.12.0): an `image` change upgrades in place, and `talos_version` in `talos_machine_configuration` is a contract pinned at creation, "not bumped on every OS upgrade".
- Planning a `talos_version` *lower* than the one in state replaces `talos_machine_secrets` (`RequiresReplace` in `talos_machine_secrets_resource.go`), which means a new PKI.
- `talosctl upgrade` without `--image` defaults to the stock installer at talosctl's own version, which would drop Image Factory extensions. v1's `manage_nodes upgrade` had this bug.

## Alternatives rejected

- `bin/tks` running `talosctl upgrade` and `upgrade-k8s` by hand. Chosen at first, before v0.12.0's resources were known. It meant more moving parts than the provider's built-in support.
- Terraform running `talosctl` from `local-exec`: a failed upgrade halfway leaves state and reality out of step.
- system-upgrade-controller or Omni: new infrastructure for two clusters.

## Consequences

- `terraform apply` *is* the upgrade, and every apply is TJ's to approve.
- `talos_machine` and `talos_cluster` were 3 weeks old when this was decided, and `ignore_kubernetes_upgrade_drift` is marked experimental. T23 exercises both on `test` before `stable` depends on them.
- Initial creation is slower under `-parallelism=1`.
