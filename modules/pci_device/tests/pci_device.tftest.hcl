variables {
  node_name   = "earth"
  description = "PCI devices with vendor 0x1002 and class 0x03"
  # An R9700 as Proxmox reports it.
  devices = [{
    id               = "0000:05:00.0"
    vendor           = "0x1002"
    device           = "0x7551"
    subsystem_vendor = "0x1002"
    subsystem_device = "0x0603"
    iommu_group      = 61
  }]
}

run "builds_the_map_entry_without_0x" {
  command = plan

  assert {
    condition = output.map == {
      node         = "earth"
      path         = "0000:05:00.0"
      id           = "1002:7551"
      subsystem_id = "1002:0603"
      iommu_group  = 61
    }
    error_message = "The entry must carry the node, address, IDs without 0x, and IOMMU group"
  }
}

run "two_matches_need_an_address" {
  command = plan

  variables {
    devices = [
      { id = "0000:05:00.0", vendor = "0x1002", device = "0x7551", subsystem_vendor = "0x1002", subsystem_device = "0x0603", iommu_group = 61 },
      { id = "0000:0e:00.0", vendor = "0x1002", device = "0x13c0", subsystem_vendor = "0x1002", subsystem_device = "0x0123", iommu_group = 30 },
    ]
  }

  expect_failures = [output.map]
}

run "an_address_chooses_between_matches" {
  command = plan

  variables {
    pci_address = "0000:0e:00.0"
    devices = [
      { id = "0000:05:00.0", vendor = "0x1002", device = "0x7551", subsystem_vendor = "0x1002", subsystem_device = "0x0603", iommu_group = 61 },
      { id = "0000:0e:00.0", vendor = "0x1002", device = "0x13c0", subsystem_vendor = "0x1002", subsystem_device = "0x0123", iommu_group = 30 },
    ]
  }

  assert {
    condition     = output.map.path == "0000:0e:00.0" && output.map.id == "1002:13c0"
    error_message = "pci_address must choose the device"
  }
}

run "an_address_that_matches_nothing_fails" {
  command = plan

  variables {
    pci_address = "0000:09:00.0"
  }

  expect_failures = [output.map]
}

run "no_device_fails" {
  command = plan

  variables {
    devices = []
  }

  expect_failures = [output.map]
}

run "a_device_without_an_iommu_group_fails" {
  command = plan

  variables {
    devices = [{ id = "0000:05:00.0", vendor = "0x1002", device = "0x7551", subsystem_vendor = "0x1002", subsystem_device = "0x0603", iommu_group = -1 }]
  }

  expect_failures = [output.map]
}
