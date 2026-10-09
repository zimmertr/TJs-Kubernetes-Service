mock_provider "proxmox" {}

mock_provider "talos" {
  mock_resource "talos_image_factory_schematic" {
    defaults = {
      id = "abc123"
    }
  }
  mock_data "talos_image_factory_urls" {
    defaults = {
      urls = {
        disk_image            = "https://factory.talos.dev/image/abc123/v1.14.2/nocloud-amd64.qcow2"
        disk_image_secureboot = "https://factory.talos.dev/image/abc123/v1.14.2/nocloud-amd64-secureboot.qcow2"
        installer             = "factory.talos.dev/nocloud-installer/abc123:v1.14.2"
        installer_secureboot  = "factory.talos.dev/nocloud-installer-secureboot/abc123:v1.14.2"
      }
    }
  }
}

variables {
  cluster_name  = "test"
  pool_name     = "general"
  talos_version = "v1.14.2"
  node_name     = "earth"
  datastore_id  = "local"
}

run "imports_an_uncompressed_qcow2" {
  command = plan

  assert {
    condition     = proxmox_download_file.this.content_type == "import"
    error_message = "VM disks import from the image, so it must use the import content type"
  }
  assert {
    condition     = data.talos_image_factory_urls.this.disk_image_format == "qcow2"
    error_message = "Proxmox can't decompress import downloads, so the image must already be qcow2"
  }
  assert {
    condition     = proxmox_download_file.this.decompression_algorithm == null
    error_message = "No decompression for import content"
  }
}

run "downloads_the_secureboot_image" {
  command = apply

  assert {
    condition     = proxmox_download_file.this.url == "https://factory.talos.dev/image/abc123/v1.14.2/nocloud-amd64-secureboot.qcow2"
    error_message = "Nodes boot with SecureBoot, so they need the signed image"
  }
}

run "file_name_is_unique_per_cluster_and_pool" {
  command = plan

  assert {
    condition     = proxmox_download_file.this.file_name == "tks-test-general-v1.14.2.qcow2"
    error_message = "File name must include the cluster, the pool and the version"
  }
}

run "extensions_reach_the_schematic" {
  command = plan

  variables {
    extensions = ["siderolabs/qemu-guest-agent", "siderolabs/amdgpu"]
  }

  assert {
    condition     = strcontains(talos_image_factory_schematic.this.schematic, "siderolabs/amdgpu")
    error_message = "Every requested extension must be in the schematic"
  }
}

run "outputs_the_installer" {
  command = apply

  assert {
    condition     = output.installer_image == "factory.talos.dev/nocloud-installer-secureboot/abc123:v1.14.2"
    error_message = "Upgrades must use the SecureBoot installer, or nodes stop booting"
  }
}
