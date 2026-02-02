# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-02-02

### ⚠️ Breaking Changes

- **Terraform Provider Upgrades**: Updated `bpg/proxmox` to `~> 0.89.1` and `siderolabs/talos` to `~> 0.9.0`
- **Talos Factory Images**: Now uses Talos Factory for custom images with QEMU Guest Agent pre-installed instead of runtime extension installation
- **Bootstrap Resource**: Changed `talos_cluster_kubeconfig` from data source to resource for better state management

### ✨ New Features

- **Talos Factory Integration**: Images are now downloaded from `factory.talos.dev` with pre-baked QEMU Guest Agent extension via schematic ID
- **New Terraform Output**: Added `talos_installer_image` output for easier node upgrades
- **Node IP Outputs**: Added `controlplane_ips` and `worker_ips` outputs for debugging and automation
- **Input Validation**: Added validation rules for `controlplane_num`, `workernode_num`, and `talos_virtual_ip` variables
- **Example tfvars**: Added `vars/cluster.tfvars` with comprehensive example configuration

### 🔧 Improvements

- **manage_nodes Script Rewrite**:
  - Complete rewrite with proper error handling (`set -euo pipefail`)
  - Added automatic cleanup of temporary files via trap
  - Now accepts both node names AND IP addresses as input
  - Improved node resolution with `resolve_node()` function
  - Better error messages with hints for troubleshooting
  - Graceful handling of terraform state locks during destroy operations
  - Added `on_failure = continue` to local-exec provisioners to prevent destroy hangs

- **Flannel Disable Fix**: Fixed config_patches to properly handle `talos_disable_flannel` flag using `concat()` instead of inline ternary with null

- **SSH Authentication**: Fixed `talos_image.tf` to use `private_key` instead of `password` for SSH connection

- **CPU Configuration**: Added explicit `units = 1024` to control plane CPU configuration

- **Code Quality**:
  - Fixed variable types: `controlplane_disk_size` and `workernode_disk_size` changed from `string` to `number`
  - Fixed `list` type annotations to `list(string)`
  - Consistent formatting throughout Terraform files

### 📚 Documentation

- **Complete README Rewrite**:
  - Modern formatting with emojis and clear sections
  - Step-by-step installation guide with numbered steps
  - Detailed prerequisites with installation commands
  - Network planning table with IP/MAC examples
  - Improved troubleshooting section with specific commands
  - Added "What You Get" feature summary table
  - Added links to external resources (Talos docs, Terraform providers)

- **Improved config.env.example**: Added inline comments explaining each environment variable

### 🔄 Version Updates

| Component | Old Version | New Version |
|-----------|-------------|-------------|
| Talos Linux | v1.5.3 | v1.10.8 |
| Kubernetes | v1.28.2 | v1.33.6 |
| QEMU Guest Agent | 8.1.0 | 10.1.2 |
| Proxmox Provider | 0.81.0 | ~> 0.89.1 |
| Talos Provider | 0.8.1 | ~> 0.9.0 |

### 🐛 Bug Fixes

- Fixed bootstrap running multiple times (changed from `count = var.controlplane_num` to `count = 1`)
- Fixed `talos_cluster_kubeconfig` to be a resource instead of data source for proper dependency tracking
- Fixed destroy operations hanging due to missing QEMU Guest Agent by adding `on_failure = continue`

---

## [1.x.x] - Previous Releases

See git history for changes prior to this major refactor.
