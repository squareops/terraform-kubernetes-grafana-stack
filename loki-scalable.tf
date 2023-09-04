resource "helm_release" "loki_scalable" {
  count = var.loki_scalable_enabled ? 1 : 0
  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.prometheus_grafana,
    helm_release.grafana_mimir
  ]
  name            = "loki-scalable"
  namespace       = var.pgl_namespace
  atomic          = false
  cleanup_on_fail = false
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "loki"
  version         = var.deployment_config.loki_scalable_config.loki_scalable_version
  values = [
    templatefile("${path.module}/helm/values/loki_scalable/${var.deployment_config.loki_scalable_config.loki_scalable_version}.yaml", {
      s3_bucket_name            = var.loki_scalable_s3_bucket_name
      loki_scalable_s3_role_arn = var.loki_scalable_role
      s3_bucket_region          = var.deployment_config.loki_scalable_config.s3_bucket_region
    }),
    var.deployment_config.loki_scalable_config.loki_scalable_values
  ]
}

resource "helm_release" "promtail" {
  count = var.loki_scalable_enabled ? 1 : 0
  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.prometheus_grafana,
    helm_release.grafana_mimir
  ]
  name            = "promtail"
  namespace       = var.pgl_namespace
  atomic          = false
  cleanup_on_fail = false
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "promtail"
  version         = var.deployment_config.promtail_config.promtail_version
  values = [
    templatefile("${path.module}/helm/values/promtail/${var.deployment_config.promtail_config.promtail_version}.yaml", {}),
    var.deployment_config.promtail_config.promtail_values
  ]
}
