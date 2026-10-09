output "file_id" {
  value       = proxmox_download_file.this.id
  description = "Datastore file ID to import VM disks from"
}

output "schematic_id" {
  value       = talos_image_factory_schematic.this.id
  description = "Image Factory schematic ID"
}

output "installer_image" {
  value       = data.talos_image_factory_urls.this.urls.installer
  description = "Installer image for this pool's nodes, used for in-place upgrades"
}
