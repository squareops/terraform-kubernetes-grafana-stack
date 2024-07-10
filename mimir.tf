resource "aws_iam_role" "mimir_role" {
  count = var.grafana_mimir_enabled ? 1 : 0
  name  = join("-", [var.cluster_name, "mimir"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:aud" = "sts.amazonaws.com",
            "${local.oidc_provider}:sub" = "system:serviceaccount:monitoring:grafana-mimir-sa"
          }
        }
      }
    ]
  })
  inline_policy {
    name = "AllowS3PutObject"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:PutObject",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

module "s3_bucket_mimir" {
  count                                 = var.grafana_mimir_enabled ? 1 : 0
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "4.1.2"
  bucket                                = var.deployment_config.mimir_s3_bucket_config.s3_bucket_name
  force_destroy                         = true
  attach_deny_insecure_transport_policy = true
  versioning = {
    enabled = var.deployment_config.mimir_s3_bucket_config.versioning_enabled
  }
  lifecycle_rule = [
    {
      id      = "mimir_s3"
      enabled = true
      expiration = {
        days = var.deployment_config.mimir_s3_bucket_config.s3_object_expiration
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
      s3_role_arn        = aws_iam_role.mimir_role[0].arn,
      s3_bucket_name     = module.s3_bucket_mimir[0].s3_bucket_id,
      s3_bucket_region   = var.deployment_config.mimir_s3_bucket_config.s3_bucket_region,
      storage_class_name = "${var.deployment_config.storage_class_name}"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Mimir"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Mimir"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Mimir"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Mimir"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Mimir"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Mimir"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Mimir"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Mimir"
    }
  }

  data = {
    "mimir-reads-resources-dashboard.json" = "${file("${path.module}/grafana/dashboards/mimir-reads-resources.json")}"
  }
}
