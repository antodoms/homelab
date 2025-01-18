data "talos_machine_configuration" "controller" {
  count = length(local.master_nodes)
  cluster_name     = local.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  machine_type     = "controlplane"
  talos_version = local.talos_version
  kubernetes_version = local.kubernetes_version
  examples           = false
  docs               = false
  config_patches = [
    yamlencode(local.common_machine_config),
    yamlencode({
      machine = {
        certSANs = [
          local.cluster_vip,
          local.master_nodes[count.index].address,
          "localhost"
        ]
        install = {
          disk = "/dev/sda"
        }
        network = {
          hostname = local.master_nodes[count.index].hostname
          nameservers = [
            local.gateway_ip
          ]
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = [
                "${local.master_nodes[count.index].address}/24"
              ]
              vip = {
                ip = local.cluster_vip
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
            name = "argocd"
            contents = join("---\n", [
              yamlencode({
                apiVersion = "v1"
                kind       = "Namespace"
                metadata = {
                  name = local.argocd_namespace
                }
              }),
              data.helm_template.argocd.manifest,
              "# Source argocd.tf\n${local.argocd_manifest}",
            ])
          }
        ]
      }
    })
  ]
}