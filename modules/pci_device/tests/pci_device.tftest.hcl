variables {
  node_name = "earth"
  address   = "0000:05:00.0"
  # Two identical R9700s and a NIC, as Proxmox reports them.
  devices = [
    { id = "0000:05:00.0", vendor = "0x1002", device = "0x7551", device_name = "Navi 48 [Radeon AI PRO R9700]", subsystem_vendor = "0x1849", subsystem_device = "0x5413", iommu_group = 61 },
    { id = "0000:06:00.0", vendor = "0x1002", device = "0x7551", device_name = "Navi 48 [Radeon AI PRO R9700]", subsystem_vendor = "0x1849", subsystem_device = "0x5413", iommu_group = 63 },
    { id = "0000:0a:00.0", vendor = "0x8086", device = "0x1533", device_name = "I210 Gigabit Network Connection", subsystem_vendor = "0x8086", subsystem_device = "0x0000", iommu_group = 20 },
  ]
}

run "builds_the_map_entry_without_0x" {
  command = plan

  assert {
    condition = output.map == {
      node         = "earth"
      path         = "0000:05:00.0"
      id           = "1002:7551"
      subsystem_id = "1849:5413"
      iommu_group  = 61
    }
    error_message = "The entry must carry the node, address, IDs without 0x, and IOMMU group"
  }
  assert {
    condition     = output.label == "1002:7551 Navi 48 [Radeon AI PRO R9700]"
    error_message = "The label must carry the model ID and the device's name"
  }
}

run "a_device_proxmox_has_no_name_for_is_labeled_by_its_id" {
  command = plan

  variables {
    devices = [{ id = "0000:05:00.0", vendor = "0x1002", device = "0x7551", device_name = null, subsystem_vendor = "0x1849", subsystem_device = "0x5413", iommu_group = 61 }]
  }

  assert {
    condition     = output.label == "1002:7551"
    error_message = "Without a name, the label must be the model ID alone"
  }
}

run "tells_identical_cards_apart_by_address" {
  command = plan

  variables {
    address = "0000:06:00.0"
  }

  assert {
    condition     = output.map.path == "0000:06:00.0" && output.map.iommu_group == 63
    error_message = "The address must choose between identical cards"
  }
}

run "an_address_with_no_device_fails" {
  command = plan

  variables {
    address = "0000:09:00.0"
  }

  expect_failures = [output.map]
}

run "a_device_without_an_iommu_group_fails" {
  command = plan

  variables {
    devices = [{ id = "0000:05:00.0", vendor = "0x1002", device = "0x7551", device_name = "Navi 48 [Radeon AI PRO R9700]", subsystem_vendor = "0x1849", subsystem_device = "0x5413", iommu_group = -1 }]
  }

  expect_failures = [output.map]
}
