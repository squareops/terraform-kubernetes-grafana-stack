output "grafana" {
  description = "Grafana_Info"
  value = {
    username = nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-user"]),
    password = nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-password"]),
    url      = var.pgl_deployment_config.hostname
  }
}
