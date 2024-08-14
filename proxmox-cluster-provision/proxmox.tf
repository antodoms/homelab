# Dynamically create VMs.
module "compute_master" {
  source                   = "./modules/master-node"
  proxmox_api_url          = local.proxmox_url
  proxmox_api_username     = local.proxmox_username
  proxmox_api_password     = local.proxmox_password
  proxmox_node             = local.proxmox_nodename
  nodes                    = local.vm_master_nodes

  proxmox_bridge           = local.proxmox_bridge
  proxmox_storage          = local.proxmox_storage
}
module "compute_worker" {
  source                   = "./modules/worker-node"
  proxmox_api_url          = local.proxmox_url
  proxmox_api_username     = local.proxmox_username
  proxmox_api_password     = local.proxmox_password
  proxmox_node             = local.proxmox_nodename
  nodes                    = local.vm_worker_nodes

  proxmox_bridge           = local.proxmox_bridge
  proxmox_storage          = local.proxmox_storage
}

output "master_mac_addrs" {
  value = module.compute_master.mac_addrs
}

output "worker_mac_addrs" {
  value = module.compute_worker.mac_addrs
}