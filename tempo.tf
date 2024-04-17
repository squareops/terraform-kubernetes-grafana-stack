resource "helm_release" "open-telemetry" {
  count      = var.deployment_config.otel_config.otel_operator_enabled ? 1 : 0
  name       = "opentelemetry-operator"
  chart      = "opentelemetry-operator"
  version    = "0.37.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  depends_on = [helm_release.prometheus_grafana]
  values = [
    templatefile("${path.module}/helm/values/otel-operator.yaml", {
      pgl_namespace = var.pgl_namespace
    })
  ]
}

resource "helm_release" "otel-collector" {
  count      = var.deployment_config.otel_config.otel_collector_enabled ? 1 : 0
  name       = "otel-collector"
  chart      = "${path.module}/helm/charts/otel-collector/"
  timeout    = 600
  namespace  = var.pgl_namespace
  depends_on = [helm_release.open-telemetry]
  values = [
    templatefile("${path.module}/helm/charts/otel-collector/values.yaml", {
      pgl_namespace = var.pgl_namespace
    })
  ]
}

resource "aws_iam_role" "s3_tempo_role" {
  count = var.tempo_enabled ? 1 : 0
  name  = join("-", [var.eks_cluster_name, "tempo"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${local.oidc_provider}"
        },
        Action = "sts:AssumeRoleWithWebIdentity"
      }
    ]
  })
  inline_policy {
    name = "AllowTempoAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject",
            "s3:GetObjectTagging",
            "s3:PutObjectTagging"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "helm_release" "tempo" {
  count      = var.tempo_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]
  name       = "tempo"
  chart      = "tempo-distributed"
  version    = "1.6.2"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://grafana.github.io/helm-charts"

  values = [
    templatefile("${path.module}/helm/values/tempo/values.yaml", {
      tempo_s3_bucket_name = var.deployment_config.tempo_config.s3_bucket_name,
      s3_bucket_region     = var.deployment_config.tempo_config.s3_bucket_region,
      tempo_role_arn       = aws_iam_role.s3_tempo_role[0].arn
    }),
    var.deployment_config.tempo_values_yaml
  ]
}

resource "aws_s3_bucket_object_lock_configuration" "tempo-s3-bucket-object_lock" {
  count  = var.tempo_enabled && var.tempo_s3_bucket_enable_object_lock ? 1 : 0
  bucket = var.tempo_enabled ? module.s3_bucket_temp[0].s3_bucket_id : null
  rule {
    default_retention {
      mode  = var.deployment_config.tempo_config.tempo_s3_bucket_object_lock_mode
      days  = var.deployment_config.tempo_config.tempo_s3_bucket_object_lock_days > 0 ? var.deployment_config.tempo_config.tempo_s3_bucket_object_lock_days : null
      years = var.deployment_config.tempo_config.tempo_s3_bucket_object_lock_years > 0 ? var.deployment_config.tempo_config.tempo_s3_bucket_object_lock_years : null
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tempo_s3_bucket_lifecycle_rules" {
  bucket   = var.tempo_enabled ? module.s3_bucket_temp[0].s3_bucket_id : null
  for_each = var.tempo_s3_bucket_lifecycle_rules
  rule {
    id = each.value.lifecycle_configuration_rule_name
    dynamic "transition" {
      for_each = each.value.enable_glacier_transition ? [1] : []
      content {
        days          = each.value.glacier_transition_days
        storage_class = "GLACIER"
      }
    }
    dynamic "transition" {
      for_each = each.value.enable_deeparchive_transition ? [1] : []
      content {
        days          = each.value.deeparchive_transition_days
        storage_class = "DEEP_ARCHIVE"
      }
    }
    dynamic "transition" {
      for_each = each.value.enable_standard_ia_transition ? [1] : []
      content {
        days          = each.value.standard_transition_days
        storage_class = "STANDARD_IA"
      }
    }
    dynamic "transition" {
      for_each = each.value.enable_one_zone_ia ? [1] : []
      content {
        days          = each.value.one_zone_ia_days
        storage_class = "ONEZONE_IA"
      }
    }
    dynamic "transition" {
      for_each = each.value.enable_intelligent_tiering ? [1] : []
      content {
        days          = each.value.intelligent_tiering_days
        storage_class = "INTELLIGENT_TIERING"
      }
    }
    dynamic "transition" {
      for_each = each.value.enable_glacier_ir ? [1] : []
      content {
        days          = each.value.glacier_ir_days
        storage_class = "GLACIER_IR"
      }
    }
    dynamic "expiration" {
      for_each = each.value.enable_current_object_expiration ? [1] : []
      content {
        days = each.value.expiration_days
      }
    }
    status = each.value.status ? "Enabled" : "Disabled"
  }
}

module "s3_bucket_temp" {
  count                                 = var.tempo_enabled ? 1 : 0
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "4.1.0"
  bucket                                = var.deployment_config.tempo_config.s3_bucket_name
  force_destroy                         = var.tempo_s3_bucket_force_destroy
  attach_deny_insecure_transport_policy = var.tempo_s3_bucket_attach_deny_insecure_transport_policy
  versioning = {
    enabled = var.deployment_config.tempo_config.versioning_enabled
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  # S3 bucket-level Public Access Block configuration
  block_public_acls       = var.tempo_s3_bucket_block_public_acls
  block_public_policy     = var.tempo_s3_bucket_block_public_policy
  ignore_public_acls      = var.tempo_s3_bucket_ignore_public_acls
  restrict_public_buckets = var.tempo_s3_bucket_restrict_public_buckets

  # S3 Bucket Ownership Controls
  object_ownership         = var.tempo_s3_bucket_object_ownership
  control_object_ownership = var.tempo_s3_bucket_control_object_ownership
}
