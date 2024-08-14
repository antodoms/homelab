data "talos_machine_configuration" "controller" {
  count = length(var.master_nodes)
  cluster_name     = local.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  machine_type     = "controlplane"
  talos_version = var.talos_version
  kubernetes_version = var.kubernetes_version
  examples           = false
  docs               = false
  config_patches = [
    yamlencode(local.common_machine_config),
    yamlencode({
      machine = {
        certSANs = [
          var.cluster_vip,
          var.master_nodes[count.index].address,
          "localhost"
        ]
        install = {
          disk = "/dev/sda"
        }
        network = {
          hostname = var.master_nodes[count.index].hostname
          nameservers = [
            var.gateway_ip
          ]
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = [
                "${var.master_nodes[count.index].address}/24"
              ]
              vip = {
                ip = var.cluster_vip
              }
            }
          ]
        }
        features = {
          kubernetesTalosAPIAccess = {
            enabled = true
            allowedRoles = [ "os:reader"]
            allowedKubernetesNamespaces = [ "talos-ccm", "kube-system" ]
          }
        }
      }
    }),
    yamlencode({
      cluster = {
        inlineManifests = [
          {
            name = "cilium"
            contents = join("---\n", [
              data.helm_template.cilium.manifest,
              "# Source cilium.tf\n${local.cilium_external_lb_manifest}",
            ])
          },
        ]
      }
    })
  ]
}