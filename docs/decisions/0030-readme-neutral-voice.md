# 0030. The README is written in neutral, professional prose and doesn't advertise TJ's other repositories

- Status: Accepted
- Date: 2026-10-10
- Decider: TJ
- Issues and PRs: #105
- Supersedes: the first-person voice in [0020](0020-readme-is-tjs.md)

## Context

[0020](0020-readme-is-tjs.md) kept the README in TJ's first-person voice. TKS has users other than TJ, and TJ asked for the README to read as professional documentation, without first person, and without pointing readers to his Kubernetes-Manifests and Application-Manifests repositories, which TKS doesn't depend on.

## Decision

- The README uses neutral, professional prose, with no "I", "my" or "me", and keeps 0020's format: the linked table of contents, `<hr>` between sections and padded tables.
- It doesn't advertise TJ's other repositories. Upstream projects TKS works with, such as the Proxmox CCM, are linked directly.
- Scaling, upgrading and `bin/manage_nodes` share one *Managing the Cluster* section, with a table of `manage_nodes` subcommands. The optional cluster features are under *Configuration Options*.
- The rest of 0020 still applies: the README is the main guide, it's kept current in every PR, and it never lies.

## Evidence

TJ's request on 2026-10-10.

## Alternatives rejected

- Keeping the first-person voice: it read as a personal project, not documentation for TKS's users.

## Consequences

- README edits are written in this voice from now on.
