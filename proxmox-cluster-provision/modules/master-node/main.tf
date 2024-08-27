# Create a new VM from a clone

resource "proxmox_vm_qemu" "talos" {

    # Dynamic provisioning of multiple nodes
    count = length(var.nodes)

    # VM General Settings
    target_node = var.proxmox_node
    name = var.nodes[count.index].node_name
    vmid = var.nodes[count.index].vm_id

    # VM Advanced General Settings
    onboot = true 

    # VM OS Settings
    clone = var.nodes[count.index].clone_target

    # VM System Settings
    agent = 0
    skip_ipv4 = true
    agent_timeout = 5
    
    # VM CPU Settings
    cores = var.nodes[count.index].node_cpu_cores
    sockets = 1
    cpu = "host"
    
    # VM Memory Settings
    memory = var.nodes[count.index].node_memory

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
                    size = var.nodes[count.index].node_disk
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
    ipconfig0 = var.nodes[count.index].node_ipconfig
}

output "mac_addrs" {
    value = [for value in proxmox_vm_qemu.talos : lower(tostring(value.network[0].macaddr))]
}