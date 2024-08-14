data "talos_machine_configuration" "worker" {
  count = length(var.worker_nodes)
  cluster_name       = local.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = "worker"
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  examples           = false
  docs               = false
  config_patches = [
    yamlencode(local.common_machine_config),
    yamlencode({
      machine = {
        install = {
          disk = "/dev/sda"
          disk = "/dev/sdb"
        }
        network = {
          hostname = var.worker_nodes[count.index].hostname
          nameservers = [
            var.gateway_ip
          ]
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = [
                "${var.worker_nodes[count.index].address}/24"
              ]
            }
          ]
        }
      }
    }),
  ]
}