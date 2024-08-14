resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/client_configuration
data "talos_client_configuration" "this" {
  cluster_name         = var.account
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for node in var.master_nodes : node.address]
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/cluster_kubeconfig
data "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = var.master_nodes[0].address
  node                 = var.master_nodes[0].address

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}

resource "talos_machine_configuration_apply" "controller" {
  count = length(var.master_nodes)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controller[count.index].machine_configuration
  node                        = var.master_nodes[count.index].address
}

resource "talos_machine_configuration_apply" "worker" {
  count = length(var.worker_nodes)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[count.index].machine_configuration
  node                        = var.worker_nodes[count.index].address
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_bootstrap
// only bootstrap the 1st master node
resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = var.master_nodes[0].address
  node                 = var.master_nodes[0].address

  depends_on = [
    talos_machine_configuration_apply.controller,
  ]
}
