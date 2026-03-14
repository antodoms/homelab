resource "proxmox_vm_qemu" "talos" {
  // ... existing configuration ...

  pcis {
    host = each.value.pcis.host
    pcie = each.value.pcis.pcie  // optional, if needed
  }

  // ... rest of configuration ...
} 