# 0017. GPU nodes carry the taint `amd.com/gpu:NoSchedule`, and pods that request the GPU tolerate it automatically

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

The GPU node is large (16 cores, 192 GB) and should run only GPU workloads.

## Decision

GPU nodes carry the taint `amd.com/gpu:NoSchedule` and the label `tks.io/pool=gpu`. Every TKS cluster's API server enables the `ExtendedResourceToleration` admission plugin, whether or not it has GPU nodes, so a pod that requests `amd.com/gpu` gets the matching toleration without declaring it. The taint and label use Talos's current node-config documents rather than the deprecated `machine.nodeTaints` and `machine.nodeLabels`.

## Evidence

`ExtendedResourceToleration` is an upstream Kubernetes admission plugin, off by default. Talos merges `enable-admission-plugins` additively, so enabling it keeps Talos's defaults. It adds tolerations for taints whose key equals an extended resource name the pod requests. Managed Kubernetes uses the same pattern (GKE taints `nvidia.com/gpu=present:NoSchedule`).

## Alternatives rejected

- Hand-written tolerations and affinities on every AI workload: repetitive, and easy to get wrong.

## Consequences

- Workloads that should run on the GPU node without requesting the GPU need an explicit toleration. That includes the AMD device plugin's own DaemonSet, and a model-download job, say.
