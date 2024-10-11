output "grafana" {
  description = "Grafana_Info"
  value = {
    username = var.deployment_config.grafana_enabled ? "admin" : null
    password = var.deployment_config.grafana_enabled ? nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-password"]) : null
    url      = var.deployment_config.grafana_enabled ? var.deployment_config.hostname : null
  }
}
