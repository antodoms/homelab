data "talos_machine_configuration" "worker" {
  count = length(local.worker_nodes)
  cluster_name       = local.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = "worker"
  talos_version      = local.talos_version
  kubernetes_version = local.kubernetes_version
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
          hostname = local.worker_nodes[count.index].hostname
          nameservers = [
            local.gateway_ip
          ]
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = [
                "${local.worker_nodes[count.index].address}/24"
              ]
            }
          ]
        }
      }
    }),
  ]
}