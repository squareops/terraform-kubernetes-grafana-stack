resource "helm_release" "grafana_mimir" {
  count      = var.grafana_mimir_enabled ? 1 : 0
  depends_on = [kubernetes_namespace.monitoring]
  name       = "grafana-mimir"
  chart      = "mimir-distributed"
  version    = var.grafana_mimir_version
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://grafana.github.io/helm-charts"

  values = [
    templatefile("${path.module}/helm/values/grafana_mimir/values.yaml", {
      backend                    = var.bucket_provider_type == "s3" ? "s3" : var.bucket_provider_type == "gcs" ? "gcs" : var.bucket_provider_type == "azure" ? "azure" : ""
      gcs_bucket_name            = var.bucket_provider_type == "gcs" ? var.gcs_bucket_name : ""
      s3_bucket_name             = var.bucket_provider_type == "s3" ? var.s3_bucket_name : ""
      s3_bucket_region           = var.bucket_provider_type == "s3" ? var.deployment_config.mimir_bucket_config.s3_bucket_region : ""
      azure_storage_account_name = var.bucket_provider_type == "azure" ? var.azure_storage_account_name : ""
      azure_container_name       = var.bucket_provider_type == "azure" ? var.azure_container_name : ""
      azure_storage_key          = var.bucket_provider_type == "azure" ? var.azure_storage_account_key : ""
      annotations                = var.bucket_provider_type == "s3" ? "eks.amazonaws.com/role-arn: ${var.role_arn}" : var.bucket_provider_type == "gcs" ? "iam.gke.io/gcp-service-account: ${var.gcp_service_account}" : var.bucket_provider_type == "azure" ? "azure.workload.identity/client-id: ${var.az_service_account}" : ""
      storage_class_name         = "${var.deployment_config.storage_class_name}"
    }),
    var.deployment_config.grafana_mimir_values_yaml
  ]
}

resource "kubernetes_config_map" "mimir-overview_dashboard" {
  count = var.grafana_mimir_enabled && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.grafana_mimir
  ]
  metadata {
    name      = "prometheus-operator-kube-p-mimir-overview-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mimir-overview-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-overview.json")}"
  }
}

resource "kubernetes_config_map" "mimir-compactor_dashboard" {
  count = var.grafana_mimir_enabled && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.grafana_mimir
  ]
  metadata {
    name      = "prometheus-operator-kube-p-mimir-compactor-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mimir-compactor-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-compactor.json")}"
  }
}

resource "kubernetes_config_map" "mimir-object-store_dashboard" {
  count = var.grafana_mimir_enabled && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.grafana_mimir
  ]
  metadata {
    name      = "prometheus-operator-kube-p-mimir-object-store-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mimir-object-store-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-object-store.json")}"
  }
}

resource "kubernetes_config_map" "mimir-queries_dashboard" {
  count = var.grafana_mimir_enabled && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.grafana_mimir
  ]
  metadata {
    name      = "prometheus-operator-kube-p-mimir-queries-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mimir-queries-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-queries.json")}"
  }
}

resource "kubernetes_config_map" "mimir-writes-resources_dashboard" {
  count = var.grafana_mimir_enabled && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.grafana_mimir
  ]
  metadata {
    name      = "prometheus-operator-kube-p-mimir-writes-resources-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mimir-writes-resources-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-writes-resources.json")}"
  }
}

resource "kubernetes_config_map" "mimir-writes_dashboard" {
  count = var.grafana_mimir_enabled && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.grafana_mimir
  ]
  metadata {
    name      = "prometheus-operator-kube-p-mimir-writes-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mimir-writes-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-writes.json")}"
  }
}

resource "kubernetes_config_map" "mimir-reads_dashboard" {
  count = var.grafana_mimir_enabled && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.grafana_mimir
  ]
  metadata {
    name      = "prometheus-operator-kube-p-mimir-reads-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mimir-reads-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-reads.json")}"
  }
}

resource "kubernetes_config_map" "mimir-reads-resources_dashboard" {
  count = var.grafana_mimir_enabled && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.grafana_mimir
  ]
  metadata {
    name      = "prometheus-operator-kube-p-mimir-reads-resources-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mimir-reads-resources-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-reads-resources.json")}"
  }
}
