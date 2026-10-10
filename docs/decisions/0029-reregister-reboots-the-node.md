# 0029. `manage_nodes reregister` reboots each node after deleting it, so it comes back on its new pod CIDR

- Status: Superseded by 0036
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #104
- Supersedes: [0028](0028-manage-nodes-reregister.md)

## Context

[0028](0028-manage-nodes-reregister.md) re-registered each node with `kubectl delete node` and a kubelet restart. On `stable` on 2026-10-10 that broke pod networking. The controller manager gives a new Node object a new pod CIDR, but Flannel only reads it, and writes its `flannel.alpha.coreos.com` annotations, when its pod starts. After the kubelet restart, Flannel and the `cni0` bridge stayed on the old CIDR, and the other nodes had no route to the node's pods. CoreDNS was on two of those nodes, so pods elsewhere couldn't resolve names, and PodDisruptionBudgets blocked the next drain. It went unnoticed on `test`, because the check there never sent pod traffic between nodes.

## Decision

`reregister` reboots the node with `talosctl reboot` after deleting it from Kubernetes, then waits for a `providerID`, Ready and, on a control plane, etcd. Flannel and the CNI bridge come up fresh on the new CIDR.

## Evidence

On `test` on 2026-10-10, after `reregister`, both nodes had new pod CIDRs (`10.244.0.0/24`, `10.244.1.0/24`), Flannel annotations, `proxmox://sol-milkyway/<vmid>` provider IDs, and CoreDNS on the new CIDR. A pod on the worker resolved `kubernetes.default.svc.cluster.local` through CoreDNS on the control plane. Before the fix, the same check showed nodes without Flannel annotations and CoreDNS on the old CIDR.

## Alternatives rejected

- Restarting Flannel's pods: `cni0` keeps its old address, and pods already running keep IPs from the old CIDR.
- Keeping each node's old pod CIDR: the controller manager allocates a new one for every new Node.

## Consequences

- Each node reboots once, so `reregister` takes about as long as `reboot`.
- Any node that was re-registered with the kubelet restart needs one `manage_nodes reboot`.
