# 0002. The GPU worker is an optional, GPU-specific module, off by default

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

TKS is an open-source project with other users. A GPU node needs things no other node does: a different Talos image, a PCI device, a taint and labels. Three shapes were considered: a generic worker-pool module used for the GPU pool, a GPU-specific module, and a separate Terraform root that joins the cluster through remote state.

## Decision

`modules/gpu_worker` is a GPU-specific module. The root module calls it only when the GPU pool has nodes, and it defaults to none. With it disabled, a plan contains no GPU resources.

## Evidence

None measured; the decision rests on readability and blast radius.

## Alternatives rejected

- A generic worker-pool module with optional PCI devices: more reusable, but more abstraction than one GPU pool needs today.
- A separate root reading TKS state: couples two state files and needs TKS to output its Talos machine secrets.

## Consequences

- Internally the module may reuse the shared node module the refactor introduces. "GPU-specific" describes its interface, not a ban on sharing code.
- Users who never enable it pay nothing for it.
