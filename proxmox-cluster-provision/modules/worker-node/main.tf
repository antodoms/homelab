# Create a new VM from a clone

resource "proxmox_vm_qemu" "talos" {
    # Dynamic provisioning of multiple nodes
    for_each = { for idx, node in var.nodes : idx => node }

    # VM General Settings
    target_node = var.proxmox_node
    name = each.value.node_name
    vmid = each.value.vm_id

    # VM Advanced General Settings
    onboot = true

    # VM OS Settings
    clone = each.value.clone_target

    # VM System Settings
    agent = 0
    skip_ipv4 = true
    agent_timeout = 5
    
    # VM CPU Settings
    cores = each.value.node_cpu_cores
    sockets = 1
    cpu = "host"    
    
    # VM Memory Settings
    memory = each.value.node_memory

    # VM Network Settings
    network {
        bridge = var.proxmox_bridge
        model  = "virtio"
    }

    # VM Disk Settings
    scsihw = "virtio-scsi-single"
    disks {
        ide {
          ide3 {
            cloudinit {
              storage = var.proxmox_storage
            }
          }
        }
        scsi {
            scsi0 {
                disk {
                    size = each.value.node_disk
                    format    = "raw"
                    iothread  = true
                    backup    = false
                    storage   = var.proxmox_storage
                }
            }
            scsi1 {
                disk {
                    size = each.value.additional_node_disk
                    format    = "raw"
                    iothread  = true
                    backup    = false
                    storage   = var.proxmox_storage
                }
            }
        }
    }

    # VM Cloud-Init Settings
    os_type = "cloud-init"
    ipconfig0 = each.value.node_ipconfig
}

output "mac_addrs" {
    value = [for value in proxmox_vm_qemu.talos : lower(tostring(value.network[0].macaddr))]
}