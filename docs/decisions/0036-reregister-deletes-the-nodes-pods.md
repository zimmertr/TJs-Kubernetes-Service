# 0036. `manage_nodes reregister` deletes the node's remaining pods along with its Node

- Status: Accepted
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #107
- Supersedes: [0029](0029-reregister-reboots-the-node.md)

## Context

[0029](0029-reregister-reboots-the-node.md) drains each node, deletes its Node object and reboots it. The drain leaves DaemonSet pods and static-pod mirrors behind. The reboot's graceful node shutdown ends the DaemonSet pods, which leaves them `Failed` or `Succeeded` but still bound to the node's name. The node registers again under that name about 30 seconds later, inside PodGC's 40-second quarantine for orphaned pods, so those pods are now bound to the new Node.

On `stable` on 2026-10-10, after `reregister k8s-node-2 k8s-node-3`, `prometheus-node-exporter` stayed one node short for 43 minutes, and MetalLB's `speaker` until its stale pod was deleted by hand. The DaemonSet controller in Kubernetes v1.37.1 queues a DaemonSet when a Node is added or its labels or taints change only if the DaemonSet should run there and has no pod bound to that node name (`syncNodeUpdate` in `pkg/controller/daemon/daemon_controller.go`). A stale pod counts as one, so recovery depends on some other event syncing the DaemonSet.

## Decision

`reregister` force-deletes every pod still bound to the node right after `kubectl delete node` and before the reboot. The new Node then has no pods bound to it, and the controller's own node-added and taint-removed handling creates each DaemonSet's pod.

## Evidence

- On `test` on 2026-10-10, four runs of the previous `reregister` on `test-k8s-node-1` left the two test DaemonSets' pods `Completed` and `Error` and bound to the absent node. The DaemonSets recovered every time, so the stall didn't reproduce there. On `stable`, the DaemonSets' `generation` was still 1, so no change to their specs triggered the late recovery.
- With this change, two runs on `test-k8s-node-1` and one on `test-k8s-cp-1` left no pods bound to the absent node. Both test DaemonSets were at their desired count within 16 seconds of the node registering. One of them doesn't tolerate `node.cloudprovider.kubernetes.io/uninitialized`, like MetalLB's speaker, and it got its pod once the CCM lifted that taint. On the control plane, the static pods' mirrors came back, etcd was healthy, and a pod there resolved `kubernetes.default.svc.cluster.local` through CoreDNS on the worker.

## Alternatives rejected

- Deleting the pods without `--force`: the kubelet would have to confirm each deletion, and the reboot may stop it first. That leaves terminating pods bound to the name until the node returns.
- Waiting out PodGC's quarantine before the reboot: it only adds time, because PodGC removes pods from nodes that are gone, and the node comes back.
- Leaving it to the DaemonSet controller: it didn't recover on `stable`, and the cause of the missed sync there is unknown.

## Consequences

- The DaemonSet pods stop a few seconds earlier than the reboot would stop them. The node is drained and already deleted from Kubernetes, so nothing depends on them.
- `kubectl` prints its warning that a force deletion doesn't wait for the container to stop. The reboot stops them.
