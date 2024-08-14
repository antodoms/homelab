server:
  config:
    url: "https://argocd.${ingress_domain}"
  certificate:
    domain: argocd.${ingress_domain}
  ingress:
    hostname: argocd.${ingress_domain}
configs:
  credentialTemplates:
    ${indent(4, argo_repository_secrets)}
  cm:
    url: https://argocd.${ingress_domain}
  repositories:
    ${indent(4, argo_repositories)}
global:
  domain: argocd.${ingress_domain}