# Security guide

How TKS handles credentials and secrets, and what CI scans. To report a vulnerability, see [`SECURITY.md`](../SECURITY.md).

## Credentials TKS uses

| Credential | Where it lives | Used for |
| --- | --- | --- |
| Proxmox API token | `vars/config.env` (gitignored) as `PROXMOX_VE_API_TOKEN` | Every provider API call |
| SSH key for the Proxmox host | `ssh-agent` | The provider's SSH-only actions, and unpacking the Talos image (v1) |

Create a dedicated user and token rather than using `root@pam`. v2 adds an optional `bootstrap/` module that creates one with a least-privilege role, and this page will list each privilege and why TKS needs it.

## Secrets in Terraform state

State holds everything needed to control the cluster: the Talos machine secrets (the cluster's certificate authorities and keys), the `talosconfig`, and an admin `kubeconfig`. Treat state as a secret:

- Never commit it. `.gitignore` excludes `*.tfstate*`.
- Keep it somewhere that is backed up and access-controlled. A remote backend with encryption and locking is better than a laptop.
- Anyone who can read the state is a cluster administrator.

The `kubeconfig` and `talosconfig` outputs are marked sensitive, so Terraform does not print them unless asked with `terraform output -raw`.

## What CI scans

| Check | What it catches |
| --- | --- |
| Trivy (`make scan`) | Generic Terraform misconfigurations at HIGH or CRITICAL severity. It has no Proxmox- or Talos-specific checks. Findings are uploaded to GitHub code scanning |
| actionlint and shellcheck (`make actionlint`) | Workflow mistakes, including untrusted input interpolated into scripts |
| GitHub secret scanning with push protection | Credentials pushed to the repository |

Every GitHub Action is pinned to a commit SHA, and each workflow job gets only the permissions it needs. [`CICD.md`](CICD.md) describes the pipeline.
