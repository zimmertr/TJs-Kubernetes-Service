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
    path      = "https://factory.talos.dev/image/${local.talos_schematic_id}/${var.talos_version}/metal-amd64.iso"
    file_name = "talos-${var.talos_version}-metal-amd64.iso"
  }

  connection {
    type     = "ssh"
    user     = var.proxmox_username
    password = var.proxmox_ssh_key_path
    host     = var.proxmox_hostname
  }
}
