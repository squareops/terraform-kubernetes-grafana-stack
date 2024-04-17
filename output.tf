output "grafana" {
  description = "Information about the grafana including username , password & URL."
  value = {
    username = "admin",
    password = nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-password"]),
    url      = var.deployment_config.hostname
  }
}
