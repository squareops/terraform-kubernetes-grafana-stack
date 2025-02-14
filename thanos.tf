module "s3_bucket_thanos" {
  count                                 = var.thanos_enabled ? 1 : 0
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "4.1.2"
  bucket                                = var.deployment_config.thanos_configs.s3_bucket_name
  force_destroy                         = true
  attach_deny_insecure_transport_policy = true
  versioning = {
    enabled = var.deployment_config.thanos_configs.versioning_enabled
  }
  lifecycle_rule = [
    {
      id      = "thanos_s3"
      enabled = true
      expiration = {
        days = var.deployment_config.thanos_configs.s3_object_expiration
      }
    }
  ]
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

  # S3 Bucket Ownership Controls
  object_ownership         = "BucketOwnerPreferred"
  control_object_ownership = true
}

resource "helm_release" "thanos" {
  count             = var.thanos_enabled ? 1 : 0
  depends_on        = [kubernetes_namespace.monitoring, kubernetes_priority_class.priority_class, helm_release.prometheus_grafana]
  name              = "thanos"
  chart             = "thanos"
  version           = var.thanos_chart_version
  timeout           = 600
  namespace         = var.pgl_namespace
  repository        = "oci://registry-1.docker.io/bitnamicharts"
  dependency_update = true
  values = [templatefile("${path.module}/helm/values/thanos/thanos.yaml", {
    storage_class_name = var.deployment_config.storage_class_name
    }),
    var.deployment_config.thanos_values_yaml
  ]
}

# resource "kubernetes_config_map" "mimir-overview_dashboard" {
#   count = var.thanos_enabled && var.deployment_config.grafana_enabled ? 1 : 0
#   depends_on = [
#     helm_release.grafana_mimir
#   ]
#   metadata {
#     name      = "prometheus-operator-kube-p-mimir-overview-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#     annotations = {
#       "grafana_folder" : "Mimir"
#     }
#   }

#   data = {
#     "mimir-overview-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-overview.json")}"
#   }
# }

# resource "kubernetes_config_map" "mimir-compactor_dashboard" {
#   count = var.thanos_enabled && var.deployment_config.grafana_enabled ? 1 : 0
#   depends_on = [
#     helm_release.grafana_mimir
#   ]
#   metadata {
#     name      = "prometheus-operator-kube-p-mimir-compactor-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#     annotations = {
#       "grafana_folder" : "Mimir"
#     }
#   }

#   data = {
#     "mimir-compactor-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-compactor.json")}"
#   }
# }

# resource "kubernetes_config_map" "mimir-object-store_dashboard" {
#   count = var.thanos_enabled && var.deployment_config.grafana_enabled ? 1 : 0
#   depends_on = [
#     helm_release.grafana_mimir
#   ]
#   metadata {
#     name      = "prometheus-operator-kube-p-mimir-object-store-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#     annotations = {
#       "grafana_folder" : "Mimir"
#     }
#   }

#   data = {
#     "mimir-object-store-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-object-store.json")}"
#   }
# }

# resource "kubernetes_config_map" "mimir-queries_dashboard" {
#   count = var.thanos_enabled && var.deployment_config.grafana_enabled ? 1 : 0
#   depends_on = [
#     helm_release.grafana_mimir
#   ]
#   metadata {
#     name      = "prometheus-operator-kube-p-mimir-queries-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#     annotations = {
#       "grafana_folder" : "Mimir"
#     }
#   }

#   data = {
#     "mimir-queries-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-queries.json")}"
#   }
# }

# resource "kubernetes_config_map" "mimir-writes-resources_dashboard" {
#   count = var.thanos_enabled && var.deployment_config.grafana_enabled ? 1 : 0
#   depends_on = [
#     helm_release.grafana_mimir
#   ]
#   metadata {
#     name      = "prometheus-operator-kube-p-mimir-writes-resources-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#     annotations = {
#       "grafana_folder" : "Mimir"
#     }
#   }

#   data = {
#     "mimir-writes-resources-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-writes-resources.json")}"
#   }
# }

# resource "kubernetes_config_map" "mimir-writes_dashboard" {
#   count = var.thanos_enabled && var.deployment_config.grafana_enabled ? 1 : 0
#   depends_on = [
#     helm_release.grafana_mimir
#   ]
#   metadata {
#     name      = "prometheus-operator-kube-p-mimir-writes-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#     annotations = {
#       "grafana_folder" : "Mimir"
#     }
#   }

#   data = {
#     "mimir-writes-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-writes.json")}"
#   }
# }

# resource "kubernetes_config_map" "mimir-reads_dashboard" {
#   count = var.thanos_enabled && var.deployment_config.grafana_enabled ? 1 : 0
#   depends_on = [
#     helm_release.grafana_mimir
#   ]
#   metadata {
#     name      = "prometheus-operator-kube-p-mimir-reads-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#     annotations = {
#       "grafana_folder" : "Mimir"
#     }
#   }

#   data = {
#     "mimir-reads-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-reads.json")}"
#   }
# }

# resource "kubernetes_config_map" "mimir-reads-resources_dashboard" {
#   count = var.thanos_enabled && var.deployment_config.grafana_enabled ? 1 : 0
#   depends_on = [
#     helm_release.grafana_mimir
#   ]
#   metadata {
#     name      = "prometheus-operator-kube-p-mimir-reads-resources-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#     annotations = {
#       "grafana_folder" : "Mimir"
#     }
#   }

#   data = {
#     "mimir-reads-resources-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-reads-resources.json")}"
#   }
# }
