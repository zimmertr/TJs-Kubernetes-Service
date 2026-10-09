resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = var.extensions
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
  # Proxmox only decompresses downloads for the iso content type, and import
  # needs an uncompressed image, so ask the factory for qcow2 directly.
  disk_image_format = "qcow2"
}

resource "proxmox_download_file" "this" {
  content_type = "import"
  node_name    = var.node_name
  datastore_id = var.datastore_id
  # The SecureBoot image enrolls Sidero Labs' keys itself on first boot, while
  # the VM's UEFI is still in setup mode.
  url       = data.talos_image_factory_urls.this.urls.disk_image_secureboot
  file_name = "tks-${var.cluster_name}-${var.pool_name}-${var.talos_version}.qcow2"
}
