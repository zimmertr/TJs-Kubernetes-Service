# 0027. An optional switch hands nodes to an external cloud controller manager, and `manage_nodes remove` stays for control planes

- Status: Accepted
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #96

## Context

Deleting a node's VM leaves its Kubernetes Node object behind until `bin/manage_nodes remove` deletes it ([0023](0023-manage-nodes-returns.md), [0025](0025-destroy-does-not-reset.md)). The Proxmox CSI plugin also needs every node labelled with its zone and region, which was a script run by hand. On managed Kubernetes, a cloud controller manager does both. TKS should stay a tool that only ships Kubernetes to Proxmox, so anything beyond that has to be optional and cost nothing when off.

## Decision

`cluster.external_cloud_provider` (default `false`) adds one patch to every node, `cluster.externalCloudProvider.enabled: true`, which runs the kubelet with `--cloud-provider=external`. TKS deploys no cloud controller manager and sets no `providerID`. The [Proxmox CCM](https://github.com/sergelogvinov/proxmox-cloud-controller-manager) is deployed from Kubernetes-Manifests, and finds each node's VM by node name and SMBIOS UUID. Its read-only user is an entry in `vars/bootstrap.tfvars`. `bin/manage_nodes remove` stays: a control plane still has to leave etcd, and draining a worker before its VM goes is still kinder than deleting it.

## Evidence

All on `test` (Talos 1.14.2, Kubernetes 1.37.1, Proxmox CCM chart 0.2.32 / v0.16.1, host-network DaemonSet on the control planes, controllers `cloud-node` and `cloud-node-lifecycle`), on 2026-10-10:

- Applying the switch to running nodes updated them in place with no reboot. Both kubelets showed `--cloud-provider=external`.
- The CCM ignored the nodes that had joined before the switch (no `providerID`, no labels). Each was initialized after `kubectl delete node` and a kubelet restart: `providerID: proxmox://sol-milkyway/<vmid>`, zone `earth`, region `sol-milkyway`, instance type `4VCPU-4GB`.
- Removing the worker from the tfvars deleted its VM. The CCM deleted its Node 53 seconds later ("does not exist in the cloud provider").
- On a cluster rebuilt with the switch on, both nodes were Ready with the `uninitialized` taint, and Flannel, CoreDNS and kube-proxy ran before any CCM. Once the CCM was installed, both nodes were initialized and untainted within seconds.
- `talos_cluster` doesn't wait for Kubernetes workloads, so the apply never blocks on the taint.

## Alternatives rejected

- A `node_labels` variable for the CSI plugin's zone and region: correct only while every node is on one host, and it overlaps with what a CCM does properly.
- Setting the zone label from each node's Proxmox host in TKS: that's the CCM's job, and it would make TKS opinionated about one CSI plugin.
- Deploying the CCM from TKS, through Talos inline manifests: it would put a token in the machine config and an in-cluster app in TKS.
- Talos's own CCM alongside the Proxmox CCM's lifecycle controller, as the Proxmox CCM's Talos example does: two controllers where one does both.

## Consequences

- With the switch on, the CCM has to be installed before any normal workload, so Kubernetes-Manifests' bootstrap starts with it.
- Turning it on for a running cluster means re-registering every node. Building the cluster with it on is simpler.
- A worker can be removed with only the apply. A control plane still needs `manage_nodes remove`.
