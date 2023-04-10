output "grafana_password" {
  description = "password"
  value       = var.deployment_config.grafana_enabled ? nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-password"]) : null
}

output "grafana_user" {
  description = "user"
  value       = var.deployment_config.grafana_enabled ? nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-user"]) : null
}
