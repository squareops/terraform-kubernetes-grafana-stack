output "grafana_password" {
  description = "grafana password"
  value       = module.pgl.grafana_password
}

output "grafana_user" {
  description = "grafana username"
  value       = module.pgl.grafana_user
}
