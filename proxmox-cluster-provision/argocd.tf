locals {
  ingress_domain   = local.config["ingress_domain"]
  argocd_domain    = "argocd.${local.ingress_domain}"
  argocd_namespace = "argocd"
  argocd_manifests = [
    # create the argocd-server tls secret.
    # NB argocd-server will automatically reload this secret.
    # NB alternatively we could set the server.certificate.enabled helm value. but
    #    that does not allow us to fully customize the certificate (e.g. subject).
    # see https://github.com/argoproj/argo-helm/blob/argo-cd-7.4.2/charts/argo-cd/templates/argocd-server/certificate.yaml
    # see https://argo-cd.readthedocs.io/en/stable/operator-manual/tls/
    # see https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
    {
      apiVersion = "cert-manager.io/v1"
      kind       = "Certificate"
      metadata = {
        name      = "argocd-server"
        namespace = local.argocd_namespace
      }
      spec = {
        subject = {
          organizations = [
            local.ingress_domain,
          ]
          organizationalUnits = [
            "Kubernetes",
          ]
        }
        commonName = "Argo CD Server"
        dnsNames = [
          local.argocd_domain,
        ]
        privateKey = {
          algorithm = "ECDSA" # NB Ed25519 is not yet supported by chrome 93 or firefox 91.
          size      = 256
        }
        duration   = "4320h" # NB 4320h (180 days). default is 2160h (90 days).
        secretName = "argocd-server-tls"
        issuerRef = {
          kind = "ClusterIssuer"
          name = "ingress"
        }
      }
    },
  ]
  argocd_manifest = join("---\n", [for d in local.argocd_manifests : yamlencode(d)])

  argo_repository_secrets = replace(yamlencode({
    "homelab-github-secret" = {
      "type": "git",
      "url": "https://github.com/antodoms",
      "githubAppID": data.sops_file.secrets.data["github_app_id"],
      "githubAppInstallationID": data.sops_file.secrets.data["github_app_installation"],
      "githubAppPrivateKey": data.sops_file.secrets.data["github_app_secret"]
    }
  }), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")

  argo_repositories = replace(yamlencode({for k in ["antodoms/homelab"] : 
     join("-", split("/", k)) => { "url": "https://github.com/${k}.git" }
  }), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
}

# set the configuration.
# NB the default values are described at:
#       https://github.com/argoproj/argo-helm/blob/argo-cd-7.4.2/charts/argo-cd/values.yaml
#    NB make sure you are seeing the same version of the chart that you are installing.
# NB this disables the tls between argocd components, that is, the internal
#    cluster traffic does not uses tls, and only the ingress uses tls.
#    see https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd#ssl-termination-at-ingress-controller
#    see https://argo-cd.readthedocs.io/en/stable/operator-manual/tls/#inbound-tls-options-for-argocd-server
#    see https://argo-cd.readthedocs.io/en/stable/operator-manual/tls/#disabling-tls-to-argocd-repo-server
#    see https://argo-cd.readthedocs.io/en/stable/operator-manual/tls/#disabling-tls-to-argocd-dex-server
# see https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/#helm
# see https://registry.terraform.io/providers/hashicorp/helm/latest/docs/data-sources/template
data "helm_template" "argocd" {
  namespace  = local.argocd_namespace
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  # see https://artifacthub.io/packages/helm/argo/argo-cd
  # renovate: datasource=helm depName=argo-cd registryUrl=https://argoproj.github.io/argo-helm
  version      = "7.4.3" # app version 2.12.0.
  kube_version = var.kubernetes_version
  api_versions = []
  values = [
    yamlencode({
        global = {
        domain = local.argocd_domain
        }
        configs = {
        params = {
            # disable tls between the argocd components.
            "server.insecure"                                = "true"
            "server.repo.server.plaintext"                   = "true"
            "server.dex.server.plaintext"                    = "true"
            "controller.repo.server.plaintext"               = "true"
            "applicationsetcontroller.repo.server.plaintext" = "true"
            "reposerver.disable.tls"                         = "true"
            "dexserver.disable.tls"                          = "true"
        }
        }
        server = {
        ingress = {
            enabled = true
            tls     = true
        }
        }
    }),
    yamlencode(yamldecode(file("${path.module}/../addons/argocd/values.yaml"))["argo-cd"]),
    templatefile("${path.module}/bootstrap/overrides/argocd-values.yaml.tpl", {
      ingress_domain = local.ingress_domain
      argo_repository_secrets = local.argo_repository_secrets
      argo_repositories = local.argo_repositories
    })
  ]
}