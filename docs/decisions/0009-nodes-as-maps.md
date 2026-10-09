# 0009. Nodes are maps keyed by hostname, with defaults for each pool

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

v1 has about 40 flat variables and creates nodes with `count`, so only the last node of a pool can be removed (the v1 README says so), and every pool repeats the same ten variables.

## Decision

Each pool (`controlplane`, `workers`, `gpu_workers`) is an object with `defaults` (cores, memory, disk size, and so on) and `nodes`, a map keyed by hostname whose values hold the IP, the VMID and any per-node override. Resources use `for_each`. Variables are typed objects with `optional()` defaults and validation: IPs inside the network CIDR, unique IPs and VMIDs, and the VIP outside the node IPs.

## Evidence

None measured.

## Alternatives rejected

- `count` with derived addresses: compact, but keeps the "last node only" limitation.

## Consequences

- Removing any node is deleting its line.
- The nine-node cap goes away.
