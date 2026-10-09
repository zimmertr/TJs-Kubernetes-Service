# 0005. An optional `bootstrap/` root module creates the Terraform user, and every cluster shares it

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

TKS needs a Proxmox API token. Today it comes from Bootstrap-Proxmox's `create_user` role, which grants a hand-maintained privilege list. The user is shared by every TKS cluster on the host, so it cannot live in a cluster workspace: destroying `test` would delete the token `stable` uses.

## Decision

A separate, optional root module, `bootstrap/`, is applied once per Proxmox cluster with root credentials. It creates a least-privilege role, a user, an ACL and an API token, and outputs the token as a sensitive value. Cluster workspaces consume the token through `config.env` as before. Users who already have a suitable token skip `bootstrap/` entirely. `docs/SECURITY_GUIDE.md` lists the privileges a token needs, each with its reason. The list is derived from the Proxmox API's documented permission checks, because Proxmox cannot report which privileges a token actually used.

## Evidence

The bpg provider offers `proxmox_virtual_environment_role`, `proxmox_virtual_environment_user`, `proxmox_acl` and `proxmox_user_token`, checked against v0.116.0 on 2026-10-09.

## Alternatives rejected

- Users in the cluster root behind a flag: one cluster's destroy deletes the shared token.
- Leaving it in Bootstrap-Proxmox: the privilege list belongs next to the code that needs those privileges.

## Consequences

- Known needs: `Sys.Audit`, `Sys.Modify` and `Datastore.AllocateTemplate` for image downloads; `Sys.Audit` on `/` to list PCI devices; `Mapping.Modify` on `/mapping/pci` to create GPU mappings.

- The proxmox-csi-plugin's user stays in Bootstrap-Proxmox. It is a Kubernetes-Manifests concern.
- The TKS entry is removed from Bootstrap-Proxmox's `create_user` variables.
