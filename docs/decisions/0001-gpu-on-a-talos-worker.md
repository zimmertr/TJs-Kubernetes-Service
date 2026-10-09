# 0001. GPU workloads run on a dedicated Talos worker node, not on a standalone VM

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

An AMD Radeon AI PRO R9700 (Navi 48, RDNA4, 32 GB) was installed in the Proxmox host `earth`. The first idea was a standalone Debian VM running Docker Compose, provisioned by Terraform and configured by Ansible, serving LLMs over HTTP. A passed-through GPU belongs to exactly one VM, so anything that needs the GPU itself, not just an HTTP API in front of it, has to run on that VM. The R9700 has no documented SR-IOV or MxGPU support, so the card cannot be split between VMs.

## Decision

The GPU is passed through to one dedicated Talos worker VM that joins an existing TKS cluster. Every GPU workload (LLM inference, later image generation) runs as Kubernetes pods scheduled onto that node. Workload manifests live in Kubernetes-Manifests and are deployed by Argo CD like every other app.

## Evidence

- Talos documents AMD GPUs through the `siderolabs/amdgpu` system extension (Talos 1.9+). Talos 1.12+ ships Linux 6.18, which contains the RDNA4 support the R9700 needs, including the GFX 12.0.1 change that landed in 6.17.
- AMD GPU Operator v1.5.1 (2026-07-21) lists the Radeon AI PRO R9700. The standalone ROCm device plugin exposes `amd.com/gpu`.
- Dedicated, tainted GPU node pools are the standard pattern on EKS, GKE and AKS.

## Alternatives rejected

- Standalone Debian and Docker VM: the GPU's workloads would live outside Kubernetes scheduling, GitOps and ingress, and it would need a second configuration system (Ansible and cloud-init).
- Converting an existing worker: special-cases one index of a uniform pool and mixes general and GPU workloads.

## Consequences

- The Debian, Ansible and Compose plan is dropped. There is no `llama-vm` repository.
- Neither the device plugin nor the operator supports time-slicing on Radeon, so one pod holds the whole GPU. Sharing happens behind one inference server (a model swapper such as llama-swap), not between pods.
- Talos with AMD GPUs is less proven than NVIDIA on Kubernetes or AMD on Debian. See [0015](0015-gpu-reset-risk-accepted.md).
