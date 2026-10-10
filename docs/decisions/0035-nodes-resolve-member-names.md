# 0035. Every node resolves cluster members' hostnames through Talos's host DNS

- Status: Accepted
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #98

## Context

The kubelet asks for its serving certificate with its bare hostname as the DNS name, for example `k8s-node-gpu-1`. kubelet-csr-approver only approves the request if that name resolves to the node's IP. On `stable` on 2026-10-10, no node's bare name resolved inside the cluster. `k8s-node-1.sol.milkyway` did, through the user's Unbound records, but the nodes have no search domain. So the approver denied `k8s-node-gpu-1` every 30 seconds, and `kubectl exec`, `logs` and metrics failed for pods on it. The other nodes were still using certificates issued earlier.

## Decision

`configs/resolver.yaml`, applied to every node, sets `hostDNS.resolveMemberNames: true` in Talos's `ResolverConfig` document. It also repeats `enabled` and `forwardKubeDNSToHost`, which are already the generated defaults. CoreDNS already forwards to Talos's host DNS, which now answers cluster members' bare hostnames from member discovery.

## Evidence

- In Talos 1.14.2, `machine.features.hostDNS` in v1alpha1 is deprecated in favour of the `ResolverConfig` document, and `talosctl gen config` emits one. On 2026-10-10, a worker config generated with this patch passed `talosctl validate --mode metal`.
- `tests/cluster.tftest.hcl` (`every_node_resolves_member_names`) checks that every pool gets the patch.
- Applied to `test` on 2026-10-10 without a reboot. Nameservers stayed `192.168.40.1`. From a pod, `test-k8s-node-1` resolved to `192.168.40.61` through the search path, and a name that isn't a member did not resolve. `test-k8s-cp-1` resolved to all of that member's addresses: its node IP, the VIP and its two Flannel addresses.

## Alternatives rejected

- A search domain through cloud-init: it only works if the user has DNS records, which TKS doesn't require (#98). The kubelet also copies it into every pod, so with `ndots:5` every external lookup tries `<name>.<domain>` first.
- `bypassDnsResolution` in the approver: it drops a check instead of making the name resolve, and every TKS user of the approver would have to know to do it.

## Consequences

Node names resolve inside the cluster with no DNS records. The patch only sets `hostDNS`, so nameservers still come from cloud-init.

A control plane's name also resolves to the VIP and its Flannel addresses. kubelet-csr-approver requires every resolved address to be in its `providerIpPrefixes`, which defaults to all addresses. Limiting that setting to the node network would deny control planes' certificates.
