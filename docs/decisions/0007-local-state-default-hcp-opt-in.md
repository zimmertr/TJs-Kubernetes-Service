# 0007. Local state stays the default, and HCP Terraform is opt-in through a gitignored override file

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

State lives in `terraform.tfstate.d/` on TJ's laptop and holds the Talos machine secrets. Losing it means losing Terraform's control of the clusters. Other TKS users must keep being able to use local state.

## Decision

TKS ships with no backend configured. TJ keeps a gitignored `cloud_override.tf` in the cluster root that selects HCP workspaces tagged `tks-cluster` (`tks-stable` and `tks-test`, which become the CLI workspace names), and a separate one in `bootstrap/` that names `tks-bootstrap` exactly, so `bootstrap/` can never select a cluster's state. Those workspaces use local execution mode: plans and applies run on the laptop, and HCP stores, locks and versions the state.

## Evidence

- HCP Terraform's free tier (since the legacy plan ended on 2026-03-31) allows 500 managed resources and one concurrent run. TKS v2 is about 30 managed resources per cluster.
- HCP's own runners cannot reach the private Proxmox API, and self-hosted agents are a paid feature, so remote execution is not an option.
- Terraform merges `*_override.tf` files into the configuration, and the standard Terraform `.gitignore` excludes them.

## Alternatives rejected

- Cloudflare R2 through the S3 backend: no advantage over a managed backend with history, at the same price.
- A `cloud {}` block committed to the repo: forces HCP on every user.

## Consequences

- The README documents the override as optional.
- HCP's free-tier terms have changed before. If they change again, the override file is the only thing to replace.
