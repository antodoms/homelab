# Dynamically create VMs.
module "compute_master" {
  for_each = local.grouped_master_node

  source                   = "./modules/master-node"
  proxmox_node             = each.key
  nodes                    = each.value

  proxmox_bridge           = local.proxmox_bridge
  proxmox_local_storage    = local.proxmox_local_storage
  proxmox_external_storage = local.proxmox_external_storage

  providers = {
    proxmox = proxmox
  }
}

module "compute_worker" {
  for_each = local.grouped_worker_node

  source                   = "./modules/worker-node"
  proxmox_node             = each.key
  nodes                    = each.value

  proxmox_bridge           = local.proxmox_bridge
  proxmox_local_storage    = local.proxmox_local_storage
  proxmox_external_storage = local.proxmox_external_storage

  providers = {
    proxmox = proxmox
  }
}

output "master_mac_addrs" {
  value = flatten([for instance in module.compute_master : instance.mac_addrs])
}

output "worker_mac_addrs" {
  value = flatten([for instance in module.compute_worker : instance.mac_addrs])
}
