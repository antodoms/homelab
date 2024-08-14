output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "kubeconfig_ca_certificate" {
  value = data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate
  sensitive = true
}

output "kubeconfig_client_certificate" {
  value = data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate
  sensitive = true
}

output "kubeconfig_client_key" {
  value = data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key
  sensitive = true
}

output "kubeconfig_host" {
  value = data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
}

output "load_balancer_ip_range" {
  value = local.cluster_lb_ip_range
}