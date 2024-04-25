resource "aws_iam_role" "mimir_role" {
  count = var.grafana_mimir_enabled ? 1 : 0
  name  = join("-", [var.eks_cluster_name, "mimir"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${local.oidc_provider}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:aud" = "sts.amazonaws.com",
            "${local.oidc_provider}:sub" = "system:serviceaccount:${var.pgl_namespace}:grafana-mimir-sa"
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

resource "aws_s3_bucket_object_lock_configuration" "mimir-s3-bucket-object_lock" {
  count  = var.grafana_mimir_enabled && var.mimir_s3_bucket_enable_object_lock ? 1 : 0
  bucket = var.grafana_mimir_enabled ? module.s3_bucket_mimir[0].s3_bucket_id : null
  rule {
    default_retention {
      mode  = var.deployment_config.mimir_s3_bucket_config.mimir_s3_bucket_object_lock_mode
      days  = var.deployment_config.mimir_s3_bucket_config.mimir_s3_bucket_object_lock_days > 0 ? var.deployment_config.mimir_s3_bucket_config.mimir_s3_bucket_object_lock_days : null
      years = var.deployment_config.mimir_s3_bucket_config.mimir_s3_bucket_object_lock_years > 0 ? var.deployment_config.mimir_s3_bucket_config.mimir_s3_bucket_object_lock_years : null
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mimir_s3_bucket_lifecycle_rules" {
  bucket = var.grafana_mimir_enabled ? module.s3_bucket_mimir[0].s3_bucket_id : null
  count  = var.grafana_mimir_enabled ? 1 : 0
  dynamic "rule" {
    for_each = var.grafana_mimir_enabled ? var.mimir_s3_bucket_lifecycle_rules : { default_rule = {} }
    content {
      id = rule.key
      dynamic "transition" {
        for_each = try(rule.value.enable_glacier_transition ? [1] : [], [])
        content {
          days          = rule.value.glacier_transition_days
          storage_class = "GLACIER"
        }
      }
      dynamic "transition" {
        for_each = try(rule.value.enable_deeparchive_transition ? [1] : [], [])
        content {
          days          = rule.value.deeparchive_transition_days
          storage_class = "DEEP_ARCHIVE"
        }
      }
      dynamic "transition" {
        for_each = try(rule.value.enable_standard_ia_transition ? [1] : [], [])
        content {
          days          = rule.value.standard_transition_days
          storage_class = "STANDARD_IA"
        }
      }
      dynamic "transition" {
        for_each = try(rule.value.enable_one_zone_ia ? [1] : [], [])
        content {
          days          = rule.value.one_zone_ia_days
          storage_class = "ONEZONE_IA"
        }
      }
      dynamic "transition" {
        for_each = try(rule.value.enable_intelligent_tiering ? [1] : [], [])
        content {
          days          = rule.value.intelligent_tiering_days
          storage_class = "INTELLIGENT_TIERING"
        }
      }
      dynamic "transition" {
        for_each = try(rule.value.enable_glacier_ir ? [1] : [], [])
        content {
          days          = rule.value.glacier_ir_days
          storage_class = "GLACIER_IR"
        }
      }
      dynamic "expiration" {
        for_each = try(rule.value.enable_current_object_expiration ? [1] : [], [])
        content {
          days = rule.value.expiration_days
        }
      }
      status = length(rule.value) > 0 ? (rule.value.status ? "Enabled" : "Disabled") : "Disabled"
    }
  }
}
module "s3_bucket_mimir" {
  count                                 = var.grafana_mimir_enabled ? 1 : 0
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "4.1.0"
  bucket                                = var.deployment_config.mimir_s3_bucket_config.s3_bucket_name
  force_destroy                         = var.mimir_s3_bucket_force_destroy
  attach_deny_insecure_transport_policy = var.mimir_s3_bucket_attach_deny_insecure_transport_policy
  versioning = {
    enabled = var.deployment_config.mimir_s3_bucket_config.versioning_enabled
  }
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  # S3 bucket-level Public Access Block configuration
  block_public_acls       = var.mimir_s3_bucket_block_public_acls
  block_public_policy     = var.mimir_s3_bucket_block_public_policy
  ignore_public_acls      = var.mimir_s3_bucket_ignore_public_acls
  restrict_public_buckets = var.mimir_s3_bucket_restrict_public_buckets

  # S3 Bucket Ownership Controls
  object_ownership         = var.mimir_s3_bucket_object_ownership
  control_object_ownership = var.mimir_s3_bucket_control_object_ownership
}

resource "helm_release" "grafana_mimir" {
  count      = var.grafana_mimir_enabled ? 1 : 0
  depends_on = [var.pgl_namespace]
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
      "chart" : "kube-prometheus-stack-35.2.0"
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
      "chart" : "kube-prometheus-stack-35.2.0"
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
      "chart" : "kube-prometheus-stack-35.2.0"
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
      "chart" : "kube-prometheus-stack-35.2.0"
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
      "chart" : "kube-prometheus-stack-35.2.0"
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
      "chart" : "kube-prometheus-stack-35.2.0"
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
      "chart" : "kube-prometheus-stack-35.2.0"
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
      "chart" : "kube-prometheus-stack-35.2.0"
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
