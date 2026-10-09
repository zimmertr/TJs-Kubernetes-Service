# 0010. Talos images are downloaded as `qcow2` and imported by the provider, without SSH

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

v1 downloads the `.raw.xz` image under an `.iso` name, because Proxmox will not accept `.xz`. It then SSHes to the host to rename and decompress the file with a `remote-exec` provisioner, and builds the Image Factory schematic with a raw `http` POST.

## Decision

`modules/talos_image` builds the schematic with the Talos provider's `talos_image_factory_schematic`. It gets the URLs from `data.talos_image_factory_urls` (`platform = "nocloud"`, `disk_image_format = "qcow2"`). It downloads the disk image with `proxmox_download_file` (`content_type = "import"`, a `.qcow2` file name, no decompression). VMs attach it with `disk.import_from`. File names include the cluster name, so clusters sharing a datastore never collide.

## Evidence

- Proxmox refuses decompression for anything except `iso` (`die "decompression not supported for $content"` in pve-storage). bpg's docs add that decompressed downloads cannot be used with `import_from`. So `.raw.zst` with `import` is not viable. (Review on 2026-10-09; a first draft of this record had chosen it.)
- `data.talos_image_factory_urls` supports `disk_image_format = "qcow2"` (siderolabs/talos v0.12.0 docs).
- The `import` content type is off by default on Proxmox storages (bpg `download_file` docs).

## Alternatives rejected

- `.raw.zst` with `decompression_algorithm = "zst"`: refused by Proxmox for `import`.
- `disk.file_id` with a raw image: imports over SSH and forces replacement.
- Keeping the rename-and-decompress provisioner: provisioners are Terraform's documented last resort, and this one hard-codes a host path.

## Consequences

- Requirement: the image datastore allows the `Import` content type.
- TKS needs no SSH access to the host, and `hashicorp/http` is no longer a dependency.
