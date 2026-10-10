# 0028. `manage_nodes reregister` registers existing nodes again after the external cloud provider is turned on

- Status: Superseded by [0029](0029-reregister-reboots-the-node.md)
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #96

## Context

A cloud controller manager only initializes a node as it registers ([0027](0027-optional-external-cloud-provider.md)). Turning on `cluster.external_cloud_provider` for a running cluster leaves every existing node without a `providerID` or topology labels, until each is drained, deleted from Kubernetes and its kubelet restarted. `stable` was the first cluster to need this, with 6 nodes. `manage_nodes reboot` can't do it, because the Node object survives a reboot.

## Decision

`bin/manage_nodes reregister [NODE...]` does it one node at a time, control planes first, in the same order as `reboot`. For each node it drains it, deletes the Node, restarts the kubelet with `talosctl`, and waits for a `providerID` and Ready. It gives up after 10 minutes without a `providerID`, which means no cloud controller manager is running. Nodes come back uncordoned, because the Node is new.

## Evidence

`./bin/manage_nodes reregister` on `test` (1 control plane, 1 worker, Proxmox CCM running) re-registered both nodes in 29 seconds on 2026-10-10, each with `providerID: proxmox://sol-milkyway/<vmid>` and zone `earth`. `shellcheck` passes.

## Alternatives rejected

- Commands in the README: TJ runs node chores through `manage_nodes`, and a typed loop is easy to get wrong across 6 nodes.
- Rebuilding the cluster: far more disruptive for a one-time change.

## Consequences

- It's only needed once per existing cluster. Nodes added later, and clusters built with the switch on, register with the CCM by themselves.
