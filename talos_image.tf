resource "proxmox_virtual_environment_file" "talos_image" {
  content_type  = "iso"
  datastore_id  = var.TALOS_IMAGE_DATASTORE
  node_name     = var.TALOS_IMAGE_WORKERNODE_NAME

  source_file {
    path        = "https://github.com/siderolabs/talos/releases/download/${var.TALOS_VERSION}/nocloud-amd64.raw.xz"
    file_name   = "talos-${var.TALOS_VERSION}-nocloud-amd64.iso"
  }
  
  connection {
    type     = "ssh"
    user     = "root"
    password = var.PROXMOX_SSH_KEY_PATH
    host     = var.PROXMOX_IP_ADDRESS
  }

  # Proxmox won't let you upload a xz archive as a disk image. So trick it by saving the file as *.iso.
  # Afterwards, use a remote-exec provisioner to name it back to *.xz and, finally, extract it. 
  provisioner "remote-exec" {
    inline = [
      "mv /var/lib/vz/template/iso/talos-${var.TALOS_VERSION}-nocloud-amd64.iso /var/lib/vz/template/iso/talos-${var.TALOS_VERSION}-nocloud-amd64.iso.xz",
      "unxz -f /var/lib/vz/template/iso/talos-${var.TALOS_VERSION}-nocloud-amd64.iso.xz"
    ]
  }
}
