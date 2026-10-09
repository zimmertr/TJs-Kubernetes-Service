# 0025. Destroying a node only deletes its VM, and `manage_nodes remove` takes a single node out of the cluster

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ
- Issues and PRs: #99

## Context

[0011](0011-in-place-upgrades-by-terraform.md) gave each `talos_machine` `on_destroy = { reset = true, graceful = true }`, so removing a node drained it, took it out of etcd and wiped it. Terraform can't tell removing one node from destroying a whole cluster, and the reset breaks the second:

- The last control plane can't leave etcd, so its reset fails.
- `terraform destroy` resets the workers in parallel. Once the others are gone, the last one can't drain past PodDisruptionBudgets, and its reset times out.

TJ wants `terraform destroy` to work with no special arguments and no README steps first.

## Decision

- `talos_machine` sets `on_destroy = { reset = false }`. Destroying a node only deletes its VM. The `reset_on_destroy` variable is gone. The value is set explicitly because `on_destroy` is optional and computed, so leaving it out would keep `reset = true` in the state of existing clusters. One `terraform apply` records the change.
- `bin/manage_nodes remove NODE` takes a single node out of the cluster, on either side of the apply:
  - If the node still answers, it drains the node, resets it gracefully (so a control plane leaves etcd), waits for etcd to drop it, and deletes the Node object.
  - If the node is gone, it removes the node's etcd member from another control plane by ID, and deletes the Node object.
  - It works through another control plane, so it refuses to remove the last one.

## Evidence

- 2026-10-09: on `test`, destroying the last control plane failed with "failed to remove member … not enough started members".
- 2026-10-09: twice on `stable`, `terraform destroy` left the last worker's reset stuck draining ("context canceled", then "timeout" after 5m). Recovering needed `terraform state rm` of every `talos_machine`.
- The Talos provider documents `on_destroy` as a no-op when `reset` is not set.
- `talosctl etcd remove-member` takes a member ID, not a hostname (talosctl v1.14.2).
- 2026-10-09, on `test`:
  - Removing a control plane with `manage_nodes remove` before the apply left one healthy etcd member and no Node object. The apply destroyed its `talos_machine` in 0s.
  - With three control planes, an apply that removed one first left a dead etcd member. `manage_nodes remove` afterwards removed it by ID.
  - Removing a worker before the apply drained and reset it cleanly.
  - `manage_nodes remove` refused the last control plane.
  - A plain `terraform destroy` with a workload whose PodDisruptionBudget allowed no evictions finished in 13s.

## Alternatives rejected

- Keep the reset and document turning it off before a destroy: that's the README step TJ doesn't want, and it needs a working apply, which you can't get once a node is stuck mid-reset.
- `graceful = false`: it skips the drain and etcd leave, so it saves nothing over no reset, and a full destroy still waits on every node.

## Consequences

- `terraform destroy` only makes Proxmox API calls, so it is fast and runs in parallel.
- Removing a control plane from the tfvars without ever running `manage_nodes remove` leaves a dead etcd member. That costs fault tolerance until someone runs it. With only two control planes, the dead member takes etcd below quorum, so nothing can remove it. On a two-control-plane cluster the script must run before the apply.
- A worker removed without the script stops without draining, like a crash.
