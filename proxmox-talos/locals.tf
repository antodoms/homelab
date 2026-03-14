locals {
  vm_master_nodes = {
    for id in range(0,length(local.master_nodes) ) : "${id}" => {
        vm_id = sum([200,id])
        node_name = local.master_nodes[id].hostname
        clone_target = "talos-${local.talos_version}-cloud-init-template"
        node_cpu_cores = local.master_nodes[id].cpu
        node_memory = local.master_nodes[id].mem
        node_ipconfig = "ip=${local.master_nodes[id].address}/24,gw=${local.gateway_ip}"
        node_disk = "200"
        node = local.master_nodes[id].node
    }
  }

  grouped_master_node = {
    for index, node in local.vm_master_nodes : node.node => node... if length([for i, n in local.vm_master_nodes : n if n.node == node.node]) > 0
  }

  vm_worker_nodes = {
    for id in range(0,length(local.worker_nodes) ) : "${id}" => {
        vm_id = sum([300,id])
        node_name = local.worker_nodes[id].hostname
        clone_target = "talos-${local.talos_version}-cloud-init-template"
        node_cpu_cores = local.worker_nodes[id].cpu
        node_memory = local.worker_nodes[id].mem
        node_ipconfig = "ip=${local.worker_nodes[id].address}/24,gw=${local.gateway_ip}"
        node_disk            = "200"
        additional_node_disk = "500" # for mayastor
        node = local.worker_nodes[id].node
    }
  }

  grouped_worker_node = {
    for index, node in local.vm_worker_nodes : node.node => node... if length([for i, n in local.vm_worker_nodes : n if n.node == node.node]) > 0
  }
}
