# 0026. `bootstrap/` also creates the Proxmox users that things running in the cluster need, from a `users` map

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ
- Issues and PRs: #101
- Supersedes: the proxmox-csi-plugin consequence of [0005](0005-bootstrap-root-for-terraform-user.md)

## Context

[0005](0005-bootstrap-root-for-terraform-user.md) left the proxmox-csi-plugin's user in Bootstrap-Proxmox's Ansible `create_user` role. TJ is moving away from Ansible, and the CSI plugin (and later, perhaps, the Proxmox CCM in #96) needs a Proxmox user and token of its own.

## Decision

`bootstrap/` takes a `users` map, keyed by user ID. Each entry names its own role, privileges and token name, and gets a role, a user, an ACL on `/` and a token that is not privilege-separated, exactly like the TKS user. The TKS user is built in: `bootstrap/` merges it into the map last, and validation refuses an entry that reuses its user ID or role. Every user shares one set of `for_each` resources. `api_token` stays the TKS token in `PROXMOX_VE_API_TOKEN` form, and `api_tokens` gives each listed user's token ID and secret separately, because tools such as the CSI plugin take them that way.

## Evidence

- The CSI plugin's install guide lists `VM.Audit VM.Config.Disk Datastore.Allocate Datastore.AllocateSpace Datastore.Audit` for its role, granted on `/`, checked on 2026-10-09.
- `terraform test` covers the merge, the validation and both outputs.

## Alternatives rejected

- A second Terraform root just for the CSI user: another state and another apply with root credentials, for four resources.
- [`sergelogvinov/terraform-proxmox-kubernetes-roles`](https://github.com/sergelogvinov/terraform-proxmox-kubernetes-roles), from the CSI plugin's author: it keeps the privilege lists upstream, but it is a third-party module with its own provider pins, and only covers CSI, CCM and Karpenter.
- The TKS user as an ordinary map entry: every tfvars file would have to repeat TKS's 25 privileges, and overriding the map would silently drop the TKS user.
- Hard-coded CSI and CCM toggles: the privilege lists would be TKS's to keep in step with projects it doesn't own.

## Consequences

- The privilege list for each extra user lives in the user's tfvars, copied from that project's docs.
- The bootstrap resources moved from `.tks` to `.this["tks@pve"]`. `moved` blocks carry an existing bootstrap's state across, so the TKS user and its token survive the upgrade. They only cover the default `user_id` of `tks@pve`.
