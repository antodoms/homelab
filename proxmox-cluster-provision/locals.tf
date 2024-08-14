locals {
  # Master Node configuration
  vm_master_nodes = {
    for id in range(0,length(var.master_nodes) ) : "${id}" => {
        vm_id = sum([200,id])
        node_name = var.master_nodes[id].hostname
        clone_target = "talos-${var.talos_version}-cloud-init-template"
        node_cpu_cores = var.master_nodes[id].cpu
        node_memory = var.master_nodes[id].mem
        node_ipconfig = "ip=${var.master_nodes[id].address}/24,gw=${var.gateway_ip}"
        node_disk = "100"
    }
  }
  vm_worker_nodes = {
    for id in range(0,length(var.worker_nodes) ) : "${id}" => {
        vm_id = sum([300,id])
        node_name = var.worker_nodes[id].hostname
        clone_target = "talos-${var.talos_version}-cloud-init-template"
        node_cpu_cores = var.worker_nodes[id].cpu
        node_memory = var.worker_nodes[id].mem
        node_ipconfig = "ip=${var.worker_nodes[id].address}/24,gw=${var.gateway_ip}"
        node_disk            = "100"
        additional_node_disk = "128" # for mayastor
    }
  }
}