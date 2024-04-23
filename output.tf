output "grafana" {
  description = "Grafana_Info"
  value = {
    username = "admin",
    password = nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-password"]),
    url      = var.deployment_config.hostname
  }
}
