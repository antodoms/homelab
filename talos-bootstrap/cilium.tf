locals {
  # see https://docs.cilium.io/en/stable/network/lb-ipam/
  # see https://docs.cilium.io/en/stable/network/l2-announcements/
  # see the CiliumL2AnnouncementPolicy type at https://github.com/cilium/cilium/blob/v1.16.0/pkg/k8s/apis/cilium.io/v2alpha1/l2announcement_types.go#L23-L42
  # see the CiliumLoadBalancerIPPool type at https://github.com/cilium/cilium/blob/v1.16.0/pkg/k8s/apis/cilium.io/v2alpha1/lbipam_types.go#L23-L47
  cilium_external_lb_manifests = [
    {
      apiVersion = "cilium.io/v2alpha1"
      kind       = "CiliumL2AnnouncementPolicy"
      metadata = {
        name = "external"
      }
      spec = {
        loadBalancerIPs = true
        interfaces = [
          "eth0",
        ]
        nodeSelector = {
          matchExpressions = [
            {
              key      = "node-role.kubernetes.io/control-plane"
              operator = "DoesNotExist"
            },
          ]
        }
      }
    },
    {
      apiVersion = "cilium.io/v2alpha1"
      kind       = "CiliumLoadBalancerIPPool"
      metadata = {
        name = "external"
      }
      spec = {
        blocks = [
          {
            start = split("-", local.cluster_lb_ip_range)[0]
            stop  = split("-", local.cluster_lb_ip_range)[1]
          },
        ]
      }
    },
  ]
  cilium_external_lb_manifest = join("---\n", [for d in local.cilium_external_lb_manifests : yamlencode(d)])
}

#  start of default TLS Cert
resource "tls_private_key" "default" {
  algorithm = "ECDSA"
}

resource "tls_self_signed_cert" "default" {
  private_key_pem = tls_private_key.default.private_key_pem

  # Certificate expires after 12 hours.
  validity_period_hours = 12

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 3

  # Reasonable set of uses for a server SSL certificate.
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["*.${local.ingress_domain}"]

  subject {
    common_name  = local.ingress_domain
    organization = "Zetech Homelab"
  }
}

resource "kubernetes_secret" "mediaserver" {
  metadata {
    name = "default-tls-cert"
    namespace = "kube-system"
  }

  data = {
    "tls.crt" = tls_self_signed_cert.default.cert_pem
    "tls.key" = tls_private_key.default.private_key_pem
  }

  type = "kubernetes.io/tls"
}

## END oF TLS Cert

// see https://www.talos.dev/v1.7/kubernetes-guides/network/deploying-cilium/#method-4-helm-manifests-inline-install
// see https://docs.cilium.io/en/stable/network/servicemesh/ingress/
// see https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/
// see https://docs.cilium.io/en/stable/gettingstarted/hubble/
// see https://docs.cilium.io/en/stable/helm-reference/#helm-reference
// see https://github.com/cilium/cilium/releases
// see https://github.com/cilium/cilium/tree/v1.16.0/install/kubernetes/cilium
// see https://registry.terraform.io/providers/hashicorp/helm/latest/docs/data-sources/template
data "helm_template" "cilium" {
  namespace  = "kube-system"
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  # renovate: datasource=helm depName=cilium registryUrl=https://helm.cilium.io
  version      = "1.16.0"
  kube_version = var.kubernetes_version
  api_versions = []
  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }
  set {
    name  = "securityContext.capabilities.ciliumAgent"
    value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  }
  set {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  }
  set {
    name  = "cgroup.autoMount.enabled"
    value = "false"
  }
  set {
    name  = "cgroup.hostRoot"
    value = "/sys/fs/cgroup"
  }
  set {
    name  = "k8sServiceHost"
    value = "localhost"
  }
  set {
    name  = "k8sServicePort"
    value = local.common_machine_config.machine.features.kubePrism.port
  }
  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }
  set {
    name  = "l2announcements.enabled"
    value = "true"
  }
  set {
    name  = "devices"
    value = "{eth0}"
  }
  set {
    name  = "ingressController.enabled"
    value = "true"
  }
  set {
    name  = "ingressController.default"
    value = "true"
  }
  set {
    name  = "ingressController.loadbalancerMode"
    value = "shared"
  }
  set {
    name  = "ingressController.enforceHttps"
    value = "false"
  }
  set {
    name = "ingressController.defaultSecretNamespace"
    value = "kube-system"
  }
  set {
    name = "ingressController.defaultSecretName"
    value = "default-tls-cert"
  }
  set {
    name  = "envoy.enabled"
    value = "true"
  }
  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }
  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }
}