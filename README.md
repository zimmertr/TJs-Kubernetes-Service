# TJ's Kubernetes Service

TJ's Kubernetes Service (TKS) builds [Talos Linux](https://www.talos.dev) Kubernetes clusters on Proxmox VE with Terraform, using the [bpg/proxmox](https://github.com/bpg/terraform-provider-proxmox) and [siderolabs/talos](https://github.com/siderolabs/terraform-provider-talos) providers. Each Terraform workspace is one cluster, configured by a tfvars file.

> **v2 is under development** ([epic #63](https://github.com/zimmertr/TJs-Kubernetes-Service/issues/63)). It is a breaking rewrite: clusters are rebuilt rather than migrated. To stay on the v1 layout, use the [`v1.0.0`](https://github.com/zimmertr/TJs-Kubernetes-Service/releases/tag/v1.0.0) tag.

## Requirements

| Requirement | Why |
| --- | --- |
| `terraform` >= 1.14.6 | Builds the cluster |
| `kubectl` and `talosctl` | Remove nodes from the cluster when Terraform destroys them |
| An SSH key in `ssh-agent` for the Proxmox host | The provider uses SSH for some API actions, and TKS uses it to unpack the Talos image |
| A Proxmox API token | Authenticates the provider. See [`docs/SECURITY_GUIDE.md`](docs/SECURITY_GUIDE.md) |
| DHCP reservations and DNS records for each node | Nodes get their addresses by DHCP, keyed to the MAC addresses TKS sets |

## Quick start

```bash
cp vars/config.env.example vars/config.env   # then fill in the API token
source vars/config.env
terraform init
terraform workspace new test
terraform apply -var-file=vars/test.tfvars
```

[`docs/USAGE.md`](docs/USAGE.md) walks through each step.

## Documentation

| Page | What it covers |
| --- | --- |
| [`docs/USAGE.md`](docs/USAGE.md) | Building, accessing, scaling and troubleshooting a cluster |
| [`docs/CONFIGURATION.md`](docs/CONFIGURATION.md) | Every input variable |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | What TKS creates and how the pieces fit |
| [`docs/SECURITY_GUIDE.md`](docs/SECURITY_GUIDE.md) | Credentials, secrets in state, and scanning |
| [`docs/CICD.md`](docs/CICD.md) | Checks, releases and dependency updates |
| [`docs/decisions/`](docs/decisions/README.md) | Why TKS is built the way it is |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to propose a change |
| [`SECURITY.md`](SECURITY.md) | How to report a vulnerability |

## License

[GPL-3.0](LICENSE)
