# Security guide

How TKS handles credentials and secrets, and what CI scans. To report a vulnerability, see [`SECURITY.md`](../SECURITY.md).

## Credentials TKS uses

| Credential | Where it lives | Used for |
| --- | --- | --- |
| Proxmox API token | `vars/config.env` (gitignored) as `PROXMOX_VE_API_TOKEN` | Every provider API call |
| Other users' API tokens | `bootstrap/` state, in the `api_tokens` output | Whatever you created them for, such as the Proxmox CSI plugin |

TKS needs no SSH access to the Proxmox host.

## The Proxmox user

Create a dedicated user and token rather than using `root@pam`. The optional `bootstrap/` root does it for you: apply it once with root credentials and `vars/bootstrap.tfvars`, and it outputs a token for `PROXMOX_VE_API_TOKEN`. Each user in that file gets its own role with only the privileges listed for it, granted on `/`, and a token that is not privilege-separated, so the token has the user's role. The `tks@pve` user there has the privileges below. `make test` runs the bootstrap tests against that file.

| Privileges | Why |
| --- | --- |
| `Datastore.AllocateSpace`, `Datastore.Audit` | Create VM, EFI and cloud-init disks |
| `Datastore.AllocateTemplate`, `Sys.Audit`, `Sys.Modify` | Download the Talos image to a datastore. `Sys.Audit` also lists the host's PCI devices |
| `Datastore.Allocate` | Delete an old Talos image after an upgrade or a destroy. Proxmox has nothing narrower for deleting a file, and this also lets the token change datastore settings |
| `Mapping.Audit`, `Mapping.Modify`, `Mapping.Use` | Create a PCI resource mapping for a GPU and attach it to a VM |
| `Pool.Allocate`, `Pool.Audit` | Create the cluster's resource pool and put VMs in it |
| `SDN.Audit`, `SDN.Use` | Attach VMs to a bridge or VLAN |
| `VM.Allocate`, `VM.Audit`, `VM.Config.*`, `VM.PowerMgmt` | Create, configure, start, stop and destroy the VMs |
| `VM.GuestAgent.Audit` | Read the QEMU guest agent's status |

The same file can list users for things running in the cluster, such as the Proxmox CSI plugin and the Proxmox CCM. Their privileges come from those projects' docs. [0026](decisions/0026-bootstrap-creates-integration-users.md)

## SecureBoot

Every node boots with UEFI SecureBoot from Talos's signed image. The VM's UEFI starts with no keys, and the image enrolls Sidero Labs' keys on first boot. After that, the firmware only boots Talos images they signed. The kernel runs in lockdown mode. [0024](decisions/0024-secureboot.md)

## Secrets in Terraform state

State holds everything needed to control the cluster: the Talos machine secrets (the cluster's certificate authorities and keys), the `talosconfig`, an admin `kubeconfig` and, for `bootstrap/`, the API tokens. Treat state as a secret:

- Never commit it. `.gitignore` excludes `*.tfstate*`.
- Keep it somewhere that is backed up and access-controlled. A remote backend with encryption and locking is better than a laptop. `cloud_override.tf.example` sets up HCP Terraform.
- Anyone who can read the state is a cluster administrator.

The `kubeconfig` and `talosconfig` outputs are marked sensitive, so Terraform does not print them unless asked with `terraform output -raw`. The kubeconfig used to drain nodes during upgrades is ephemeral and never written to state.

## What CI scans

| Check | What it catches |
| --- | --- |
| Trivy (`make scan`) | Generic Terraform misconfigurations at HIGH or CRITICAL severity. It has no Proxmox- or Talos-specific checks. Findings are uploaded to GitHub code scanning |
| actionlint and shellcheck (`make actionlint`) | Workflow mistakes, including untrusted input interpolated into scripts |
| GitHub secret scanning with push protection | Credentials pushed to the repository |

Every GitHub Action is pinned to a commit SHA, and each workflow job gets only the permissions it needs. [`CICD.md`](CICD.md) describes the pipeline.
