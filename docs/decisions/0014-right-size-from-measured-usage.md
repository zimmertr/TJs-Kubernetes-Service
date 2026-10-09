# 0014. `stable` is right-sized from measured usage to make room for a 192 GB GPU node

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

The host is treated as having 384 GB of RAM because one of its four 128 GB DIMMs is unreliable. A passed-through VM pins all of its memory, and will not start unless the host has all of it free. llama.cpp can run large MoE models partly from system RAM, so the GPU node's RAM decides which models fit.

## Decision

| VM | v1 | v2 |
|---|---|---|
| k8s-cp-1..3 | 4 cores, 10 GB | 4 cores, 8 GB |
| k8s-node-1..3 | 10 cores, 50 GB | 6 cores, 24 GB |
| k8s-node-gpu-1 | none | 16 cores, 192 GB |
| test-k8s-node-gpu-1 | none | 8 cores, 32 GB (borrows the GPU only while `stable`'s GPU node is absent) |

Committed memory is 296 GB, which leaves about 88 GB for Proxmox, the ZFS cache and headroom.

## Evidence

Measured on 2026-10-09.

| Node | CPU p95 (220 days, Proxmox) | Memory in use (`kubectl top`) | Pod memory requests | Pod memory limits |
|---|---|---|---|---|
| k8s-cp-1..3 | about 8% of 4 cores | 2.4 to 3.2 GB | about 1 GB | under 0.3 GB |
| k8s-node-1 | 13% of 10 cores | 6.8 GB | 3.8 GB | 5.1 GB |
| k8s-node-2 | 8% of 10 cores | 3.6 GB | 1.5 GB | 4.1 GB |
| k8s-node-3 | 17% of 10 cores | 3.6 GB | 2.1 GB | 6.3 GB |

Proxmox's memory history is the host-side resident size (there are no balloon statistics), which includes the guests' page cache. It shows workers at their 50 GB ceiling, which is not demand.

## Alternatives rejected

- A 128 GB GPU node with v1-sized workers: rules out the 235B class of MoE models in order to keep about 136 GB of worker memory idle.

## Consequences

- If the bad DIMM is pulled, memory bandwidth drops by about a quarter (three of four channels), and CPU-offloaded tokens slow down accordingly.
