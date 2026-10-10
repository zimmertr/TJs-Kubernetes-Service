mock_provider "proxmox" {}

# The real Talos provider, because mocks can't stand in for the ephemeral
# drain kubeconfig. Everything it does during a plan is offline.

override_module {
  target          = module.image
  override_during = plan
  outputs = {
    file_id         = "local:import/tks-test-general-v1.14.2.qcow2"
    installer_image = "factory.talos.dev/nocloud-installer/abc123:v1.14.2"
  }
}
variables {
  proxmox = { node_name = "earth", resource_pool = "Kubernetes-Test" }
  network = { cidr = "192.168.40.0/24", gateway = "192.168.40.1", dns_servers = ["192.168.40.1"], vlan_id = 40 }
  cluster = { name = "test", vip = "192.168.40.50", talos_config_version = "v1.14.2" }
  controlplanes = {
    defaults = { memory_mb = 4096 }
    nodes = {
      "test-k8s-cp-1" = { ip = "192.168.40.51", vm_id = 4051 }
      "test-k8s-cp-2" = { ip = "192.168.40.52", vm_id = 4052, cores = 8 }
    }
  }
  workers = {
    nodes = {
      "test-k8s-node-1" = { ip = "192.168.40.61", vm_id = 4061 }
    }
  }
}

run "pool_defaults_fill_in_what_a_node_does_not_set" {
  command = plan

  assert {
    condition     = local.controlplanes["test-k8s-cp-1"].cores == 4 && local.controlplanes["test-k8s-cp-1"].memory_mb == 4096
    error_message = "A node without its own sizing must get the pool's defaults"
  }
  assert {
    condition     = local.controlplanes["test-k8s-cp-2"].cores == 8
    error_message = "A node's own sizing must win over the pool's defaults"
  }
}

run "each_node_gets_its_own_hostname" {
  command = plan

  assert {
    condition     = strcontains(local.workers["test-k8s-node-1"].config_patches[length(local.workers["test-k8s-node-1"].config_patches) - 1], "test-k8s-node-1")
    error_message = "The hostname patch must carry the node's map key"
  }
}

run "only_control_planes_get_the_vip" {
  command = plan

  assert {
    condition     = anytrue([for p in local.controlplanes["test-k8s-cp-1"].config_patches : strcontains(p, "192.168.40.50")])
    error_message = "Control planes must share the virtual IP"
  }
  assert {
    condition     = !anytrue([for p in local.workers["test-k8s-node-1"].config_patches : strcontains(p, "192.168.40.50")])
    error_message = "Workers must not claim the virtual IP"
  }
}

run "feature_patches_are_off_by_default" {
  command = plan

  assert {
    condition     = length(local.controlplanes["test-k8s-cp-1"].config_patches) == 4 && length(local.workers["test-k8s-node-1"].config_patches) == 3
    error_message = "Without disable_flannel, expose_metrics or external_cloud_provider, only the global, resolver, VIP and hostname patches apply"
  }
}

run "feature_patches_apply_when_switched_on" {
  command = plan

  variables {
    cluster = { name = "test", vip = "192.168.40.50", talos_config_version = "v1.14.2", disable_flannel = true, expose_metrics = true }
  }

  assert {
    condition     = length(local.controlplanes["test-k8s-cp-1"].config_patches) == 6 && length(local.workers["test-k8s-node-1"].config_patches) == 3
    error_message = "disable_flannel and expose_metrics apply to control planes only"
  }
}

run "external_cloud_provider_applies_to_every_node" {
  command = plan

  variables {
    cluster = { name = "test", vip = "192.168.40.50", talos_config_version = "v1.14.2", external_cloud_provider = true }
  }

  assert {
    condition     = length(local.controlplanes["test-k8s-cp-1"].config_patches) == 5 && length(local.workers["test-k8s-node-1"].config_patches) == 4
    error_message = "external_cloud_provider must reach the kubelet on control planes and workers alike"
  }

  assert {
    condition     = strcontains(local.workers["test-k8s-node-1"].config_patches[2], "externalCloudProvider")
    error_message = "The worker's extra patch must be the external cloud provider one"
  }
}

run "workers_are_optional" {
  command = plan

  variables {
    workers = {}
  }

  assert {
    condition     = length(local.workers) == 0
    error_message = "A cluster can be control planes only"
  }
}

run "every_node_resolves_member_names" {
  command = plan

  variables {
    gpu_workers = { nodes = { "test-k8s-node-gpu-1" = { ip = "192.168.40.71", vm_id = 4071, pci_address = "05:00.0" } } }
  }

  override_module {
    target  = module.gpu_image
    outputs = { file_id = "local:import/tks-test-gpu-v1.14.2.qcow2", installer_image = "factory.talos.dev/nocloud-installer/def456:v1.14.2" }
  }
  override_module {
    target  = module.gpu_workers
    outputs = { nodes = {}, machines = {}, mappings = {} }
  }

  assert {
    condition = alltrue([
      for n in merge(local.controlplanes, local.workers, local.gpu_workers) :
      anytrue([for p in n.config_patches : strcontains(p, "kind: ResolverConfig") && strcontains(p, "resolveMemberNames: true")])
    ])
    error_message = "Every node must resolve cluster members' hostnames, so node names resolve without DNS records"
  }
}

run "gpu_workers_are_off_by_default" {
  command = plan

  assert {
    condition     = length(module.gpu_image) == 0 && length(module.gpu_workers) == 0
    error_message = "Without GPU nodes, no GPU image, mapping or VM is planned"
  }
}

run "gpu_workers_get_their_own_image_taint_and_label" {
  command = plan

  variables {
    cluster = { name = "test", vip = "192.168.40.50", talos_config_version = "v1.14.2", external_cloud_provider = true }
    gpu_workers = {
      defaults = { cores = 16, memory_mb = 196608 }
      nodes = {
        "test-k8s-node-gpu-1" = { ip = "192.168.40.71", vm_id = 4071, pci_address = "05:00.0" }
      }
    }
  }

  override_module {
    target = module.gpu_image
    outputs = {
      file_id         = "local:import/tks-test-gpu-v1.14.2.qcow2"
      installer_image = "factory.talos.dev/nocloud-installer/def456:v1.14.2"
    }
  }
  # The PCI lookup can't be mocked here; modules/pci_device tests it.
  override_module {
    target = module.gpu_workers
    outputs = {
      nodes    = { "test-k8s-node-gpu-1" = { ip = "192.168.40.71", vm_id = 4071, proxmox_node = "earth" } }
      machines = {}
      mappings = { "test-k8s-node-gpu-1" = "test-gpu-4071" }
    }
  }

  assert {
    condition     = local.gpu_workers["test-k8s-node-gpu-1"].pci_address == "0000:05:00.0"
    error_message = "An address without its domain must get the 0000: that Proxmox reports"
  }
  assert {
    condition     = local.gpu_workers["test-k8s-node-gpu-1"].cores == 16 && local.gpu_workers["test-k8s-node-gpu-1"].memory_mb == 196608
    error_message = "GPU nodes must get the GPU pool's defaults"
  }
  assert {
    condition     = strcontains(local.gpu_workers["test-k8s-node-gpu-1"].config_patches[0], "def456") && !strcontains(local.gpu_workers["test-k8s-node-gpu-1"].config_patches[0], "abc123")
    error_message = "GPU nodes must install and upgrade from the GPU image, which carries the driver"
  }
  assert {
    condition     = strcontains(local.gpu_workers["test-k8s-node-gpu-1"].config_patches[2], "externalCloudProvider")
    error_message = "Cluster-wide patches must reach GPU nodes too"
  }
  assert {
    condition     = anytrue([for p in local.gpu_workers["test-k8s-node-gpu-1"].config_patches : strcontains(p, "amd.com/gpu: NoSchedule") && strcontains(p, "tks.io/pool: gpu")])
    error_message = "GPU nodes must carry the GPU taint and pool label"
  }
  assert {
    condition     = !anytrue([for p in local.workers["test-k8s-node-1"].config_patches : strcontains(p, "amd.com/gpu")])
    error_message = "General workers must not get the GPU taint"
  }
  assert {
    condition     = strcontains(local.gpu_workers["test-k8s-node-gpu-1"].config_patches[length(local.gpu_workers["test-k8s-node-gpu-1"].config_patches) - 1], "test-k8s-node-gpu-1")
    error_message = "The hostname patch must come last"
  }
  assert {
    condition     = output.nodes["test-k8s-node-gpu-1"].role == "worker"
    error_message = "GPU nodes must be listed for manage_nodes as workers"
  }
  assert {
    condition     = contains(data.talos_client_configuration.this.nodes, "192.168.40.71")
    error_message = "talosctl must be able to reach GPU nodes"
  }
}

run "rejects_a_gpu_node_ip_in_another_pool" {
  command = plan

  variables {
    gpu_workers = { nodes = { "test-k8s-node-gpu-1" = { ip = "192.168.40.61", vm_id = 4071, pci_address = "0000:05:00.0" } } }
  }

  expect_failures = [var.workers]
}

run "rejects_a_gpu_hostname_in_another_pool" {
  command = plan

  variables {
    gpu_workers = { nodes = { "test-k8s-node-1" = { ip = "192.168.40.71", vm_id = 4071, pci_address = "0000:05:00.0" } } }
  }

  expect_failures = [var.workers]
}

run "rejects_a_vip_that_is_a_gpu_node_ip" {
  command = plan

  variables {
    gpu_workers = { nodes = { "test-k8s-node-gpu-1" = { ip = "192.168.40.50", vm_id = 4071, pci_address = "0000:05:00.0" } } }
  }

  expect_failures = [var.cluster]
}

run "rejects_two_gpu_nodes_on_one_gpu" {
  command = plan

  variables {
    gpu_workers = {
      nodes = {
        "test-k8s-node-gpu-1" = { ip = "192.168.40.71", vm_id = 4071, pci_address = "0000:05:00.0" }
        "test-k8s-node-gpu-2" = { ip = "192.168.40.72", vm_id = 4072, pci_address = "0000:05:00.0" }
      }
    }
  }

  expect_failures = [var.gpu_workers]
}

run "rejects_a_malformed_pci_address" {
  command = plan

  variables {
    gpu_workers = { nodes = { "test-k8s-node-gpu-1" = { ip = "192.168.40.71", vm_id = 4071, pci_address = "05:00" } } }
  }

  expect_failures = [var.gpu_workers]
}

run "rejects_one_gpu_written_two_ways" {
  command = plan

  variables {
    gpu_workers = {
      nodes = {
        "test-k8s-node-gpu-1" = { ip = "192.168.40.71", vm_id = 4071, pci_address = "05:00.0" }
        "test-k8s-node-gpu-2" = { ip = "192.168.40.72", vm_id = 4072, pci_address = "0000:05:00.0" }
      }
    }
  }

  expect_failures = [var.gpu_workers]
}

run "the_first_control_plane_bootstraps" {
  command = plan

  assert {
    condition     = talos_cluster.this.node == "192.168.40.51"
    error_message = "etcd must be bootstrapped on the first control plane by name"
  }
}

run "rejects_a_config_version_newer_than_talos" {
  command = plan

  variables {
    cluster = { name = "test", vip = "192.168.40.50", talos_version = "v1.14.2", talos_config_version = "v1.15.0" }
  }

  expect_failures = [var.cluster]
}

run "rejects_a_vip_outside_the_network" {
  command = plan

  variables {
    cluster = { name = "test", vip = "10.0.0.10", talos_config_version = "v1.14.2" }
  }

  expect_failures = [var.cluster]
}

run "rejects_a_vip_that_is_a_node_ip" {
  command = plan

  variables {
    cluster = { name = "test", vip = "192.168.40.51", talos_config_version = "v1.14.2" }
  }

  expect_failures = [var.cluster]
}

run "rejects_duplicate_ips" {
  command = plan

  variables {
    workers = { nodes = { "test-k8s-node-1" = { ip = "192.168.40.51", vm_id = 4061 } } }
  }

  expect_failures = [var.workers]
}

run "rejects_duplicate_vmids" {
  command = plan

  variables {
    workers = { nodes = { "test-k8s-node-1" = { ip = "192.168.40.61", vm_id = 4051 } } }
  }

  expect_failures = [var.workers]
}

run "rejects_a_hostname_in_two_pools" {
  command = plan

  variables {
    workers = { nodes = { "test-k8s-cp-1" = { ip = "192.168.40.61", vm_id = 4061 } } }
  }

  expect_failures = [var.workers]
}

run "rejects_a_node_outside_the_network" {
  command = plan

  variables {
    workers = { nodes = { "test-k8s-node-1" = { ip = "10.0.0.61", vm_id = 4061 } } }
  }

  expect_failures = [var.workers]
}

run "requires_a_control_plane" {
  command = plan

  variables {
    controlplanes = { nodes = {} }
  }

  expect_failures = [var.controlplanes]
}
