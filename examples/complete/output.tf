output "grafana_credentials" {
  description = "Information about the grafana including username , password & URL."
  value       = module.pgl.grafana
}
