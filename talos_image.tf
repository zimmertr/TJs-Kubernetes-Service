data "http" "talos_schematic" {
  url    = "https://factory.talos.dev/schematics"
  method = "POST"

  request_headers = {
    Content-Type = "application/yaml"
  }

  request_body = file("${path.module}/configs/talos_image_factory.yml")
}

locals {
  talos_schematic_id = jsondecode(data.http.talos_schematic.response_body).id
}


resource "proxmox_virtual_environment_file" "talos_image" {
  content_type = "iso"
  datastore_id = var.talos_image_datastore
  node_name    = var.talos_image_node_name

  source_file {
    path      = "https://factory.talos.dev/image/${local.talos_schematic_id}/${var.talos_version}/nocloud-amd64.raw.xz"
    file_name = "talos-${var.talos_version}-nocloud-amd64.iso"
  }

  connection {
    type        = "ssh"
    user        = var.proxmox_username
    private_key = file(var.proxmox_ssh_key_path)
    host        = var.proxmox_hostname
  }

  # Proxmox won't let you upload a xz archive as a disk image. So trick it by saving the file as *.iso.
  # Afterwards, use a remote-exec provisioner to name it back to *.xz and, finally, extract it. 
  provisioner "remote-exec" {
    inline = [
      "mv /var/lib/vz/template/iso/talos-${var.talos_version}-nocloud-amd64.iso /var/lib/vz/template/iso/talos-${var.talos_version}-nocloud-amd64.iso.xz",
      "unxz -f /var/lib/vz/template/iso/talos-${var.talos_version}-nocloud-amd64.iso.xz"
    ]
  }
}
