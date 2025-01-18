resource "talos_machine_secrets" "this" {
  talos_version = local.talos_version
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/client_configuration
data "talos_client_configuration" "this" {
  cluster_name         = var.account
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for node in local.master_nodes : node.address]
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/cluster_kubeconfig
data "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = local.master_nodes[0].address
  node                 = local.master_nodes[0].address

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}

resource "talos_machine_configuration_apply" "controller" {
  count = length(local.master_nodes)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controller[count.index].machine_configuration
  node                        = local.master_nodes[count.index].address
}

resource "talos_machine_configuration_apply" "worker" {
  count = length(local.worker_nodes)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[count.index].machine_configuration
  node                        = local.worker_nodes[count.index].address
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_bootstrap
// only bootstrap the 1st master node
resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = local.master_nodes[0].address
  node                 = local.master_nodes[0].address

  depends_on = [
    talos_machine_configuration_apply.controller,
  ]
}
