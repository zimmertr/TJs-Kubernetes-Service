# Users ########################
users = {
  # The privileges are explained in docs/SECURITY_GUIDE.md.
  "tks@pve" = {
    role       = "TKS"
    token_name = "terraform"
    comment    = "Terraform user for TJ's Kubernetes Service"
    privileges = [
      "Datastore.Allocate",
      "Datastore.AllocateSpace",
      "Datastore.AllocateTemplate",
      "Datastore.Audit",
      "Mapping.Audit",
      "Mapping.Modify",
      "Mapping.Use",
      "Pool.Allocate",
      "Pool.Audit",
      "SDN.Audit",
      "SDN.Use",
      "Sys.Audit",
      "Sys.Modify",
      "VM.Allocate",
      "VM.Audit",
      "VM.Config.CDROM",
      "VM.Config.CPU",
      "VM.Config.Cloudinit",
      "VM.Config.Disk",
      "VM.Config.HWType",
      "VM.Config.Memory",
      "VM.Config.Network",
      "VM.Config.Options",
      "VM.GuestAgent.Audit",
      "VM.PowerMgmt",
    ]
  }

  "kubernetes-csi@pve" = {
    role       = "CSI"
    token_name = "csi"
    comment    = "Proxmox CSI Plugin"
    privileges = ["Datastore.Allocate", "Datastore.AllocateSpace", "Datastore.Audit", "VM.Audit", "VM.Config.Disk"]
  }

  "kubernetes-ccm@pve" = {
    role       = "CCM"
    token_name = "ccm"
    comment    = "Proxmox Cloud Controller Manager"
    privileges = ["Sys.Audit", "VM.Audit", "VM.GuestAgent.Audit"]
  }
}
