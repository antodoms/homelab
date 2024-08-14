locals {
  cluster_name = var.account
  common_machine_config = {
    machine = {
      sysctls = {
        "vm.nr_hugepages" = "1024"
      }
      nodeLabels = {
        "openebs.io/engine" = "mayastor"
      }
      kubelet = {
        # Below config is required by TalosCCM but we are not using TalosCCM cause it was causing the bootstrap to fail
        # extraArgs = {
        #   cloud-provider = "external"
        #   rotate-server-certificates = true
        # }
        extraMounts = [
          {
            destination = "/var/local"
            type = "bind"
            source = "/var/local"
            options = ["bind", "rshared", "rw"]
          }
        ]
      }
      features = {
        rbac = true
        stableHostname = true
        apidCheckExtKeyUsage = true
        diskQuotaSupport = true
        kubePrism = {
          enabled = true
          port    = 7445
        }
        hostDNS = {
          enabled = true
          resolveMemberNames = true
          forwardKubeDNSToHost = true
        }
      }
      network = {
        kubespan = {
          enabled: true
        }
      }
    }

    cluster = {
      # see https://www.talos.dev/v1.7/talos-guides/discovery/
      # see https://www.talos.dev/v1.7/reference/configuration/#clusterdiscoveryconfig
      discovery = {
        enabled = true
        registries = {
          kubernetes = {
            disabled = true
          }
          service = {
            disabled = true
          }
        }
      }
      proxy = {
        disabled = true
        # extraArgs = {
        #   ipvs-strict-arp = true
        # }
      }
      network = {
        cni = {
          name = "none"
        }
      }
    }
  }
}