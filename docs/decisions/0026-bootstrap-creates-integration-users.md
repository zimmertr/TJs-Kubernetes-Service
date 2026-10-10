# 0026. `bootstrap/` creates every Proxmox user from a `users` map in `vars/bootstrap.tfvars`, including the one TKS runs as

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ
- Issues and PRs: #101
- Supersedes: [0005](0005-bootstrap-root-for-terraform-user.md)

## Context

[0005](0005-bootstrap-root-for-terraform-user.md) gave `bootstrap/` a built-in `tks@pve` user, and left the Proxmox CSI plugin's user in Bootstrap-Proxmox's Ansible `create_user` role. TJ is moving away from Ansible, and the CSI plugin and the Proxmox CCM (#96) each need a Proxmox user and token. TKS should stay a tool that ships Kubernetes to Proxmox and holds as few opinions as possible: an admin might already have a user for TKS.

## Decision

`bootstrap/` takes one required `users` map, keyed by user ID. Each entry names its role, privileges and token name, and gets a role, a user, an ACL on `/` and a token that is not privilege-separated. Nothing is built in: the `tks@pve` user and its privileges are an entry in `vars/bootstrap.tfvars`, next to the cluster tfvars, alongside the CSI and CCM users. The `api_tokens` output maps each user to its token as `<id>=<secret>`. `make test` runs the bootstrap tests with `vars/bootstrap.tfvars`, so the privileges that get applied are the ones tested.

## Evidence

- The CSI plugin's install guide lists `VM.Audit VM.Config.Disk Datastore.Allocate Datastore.AllocateSpace Datastore.Audit`, and the CCM's lists `VM.Audit VM.GuestAgent.Audit Sys.Audit`, both granted on `/`, checked on 2026-10-09.
- `terraform test` covers the roles, ACLs, tokens and output for the committed file.

## Alternatives rejected

- A built-in TKS user merged into the map: it makes TKS opinionated, and an admin with their own user can't leave it out.
- A second Terraform root just for the CSI user: another state and another apply with root credentials, for four resources.
- [`sergelogvinov/terraform-proxmox-kubernetes-roles`](https://github.com/sergelogvinov/terraform-proxmox-kubernetes-roles), from the CSI plugin's author: a third-party module with its own provider pins, covering only CSI, CCM and Karpenter.
- Rewriting Bootstrap-Proxmox in Terraform: most of it configures the host itself (packages, files, the kernel command line), which needs a shell, not an API.
- `moved` blocks from the old `.tks` addresses: an existing bootstrap is destroyed and applied again instead.

## Consequences

- A TKS change that needs a new privilege updates `vars/bootstrap.tfvars` and `docs/SECURITY_GUIDE.md` together. Anyone with their own copy adds it by hand.
- Applying this over a bootstrap from before it fails on the duplicate role and user IDs. Destroy the old bootstrap first, and put the new `tks@pve` token in `config.env`.
- Applying without `-var-file` prompts for `users` rather than planning to delete every user.
