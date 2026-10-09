# 0004. TKS assumes a ready hypervisor, and host configuration stays out of it

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

Bootstrap-Proxmox, a separate Ansible repository, configures TJ's host: APT repositories, IOMMU, Postfix, Sanoid, ZED, fan control, NFS, ZFS imports, the Proxmox cluster and API users. Folding some of it into TKS was considered. Things that exist once per host (APT repositories, storage settings) cannot live in a cluster workspace, because two clusters would fight over them, and destroying one would revert them for the other.

## Decision

TKS builds Kubernetes on a Proxmox host that is already configured. It manages only Proxmox objects that belong to a cluster (VMs, pools, image files, PCI mappings), plus the optional Terraform user in [0005](0005-bootstrap-root-for-terraform-user.md). Host prerequisites appear only as rows in the README's Requirements table, never as commands or scripts.

## Evidence

- The Proxmox admin guide says the IOMMU is on by default for Intel CPUs with kernel 6.8 or newer, and qemu-server binds a passed-through device to `vfio-pci` itself when the VM starts. Bootstrap-Proxmox's `enable_iommu` role is redundant and is deleted rather than ported.

## Alternatives rejected

- Optional host features (APT repositories, thin provisioning) in a `proxmox/` root module: scope creep for a "Kubernetes on Proxmox" project, for settings TJ changes by hand once.

## Consequences

- FlashPool thin provisioning was set by hand on 2026-10-09 (`sparse 1`, with `refreservation=none` on the existing non-cluster volumes). No code records it.
- A GPU host-driver setting, if the reset test needs one, goes in Bootstrap-Proxmox.
