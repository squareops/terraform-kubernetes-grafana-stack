resource "aws_iam_role" "loki_scalable_role" {
  count      = var.loki_scalable_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana, helm_release.grafana_mimir]
  name       = join("-", [var.eks_cluster_name, "loki-scalable"])
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
            "${local.oidc_provider}:sub" = "system:serviceaccount:${var.pgl_namespace}:loki-canary"
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

resource "aws_s3_bucket_object_lock_configuration" "loki-scalable-s3-bucket-object_lock" {
  count  = var.loki_scalable_enabled && var.loki_scalable_s3_bucket_enable_object_lock ? 1 : 0
  bucket = var.loki_scalable_enabled ? module.loki_scalable_s3_bucket[0].s3_bucket_id : null
  rule {
    default_retention {
      mode  = var.deployment_config.loki_scalable_config.loki_scalable_s3_bucket_object_lock_mode
      days  = var.deployment_config.loki_scalable_config.loki_scalable_s3_bucket_object_lock_days > 0 ? var.deployment_config.loki_scalable_config.loki_scalable_s3_bucket_object_lock_days : null
      years = var.deployment_config.loki_scalable_config.loki_scalable_s3_bucket_object_lock_years > 0 ? var.deployment_config.loki_scalable_config.loki_scalable_s3_bucket_object_lock_years : null
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki_scalable_s3_bucket_lifecycle_rules" {
  bucket   = var.loki_scalable_enabled ? module.loki_scalable_s3_bucket[0].s3_bucket_id : null
  for_each = var.loki_scalable_s3_bucket_lifecycle_rules
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

module "loki_scalable_s3_bucket" {
  count                                 = var.loki_scalable_enabled ? 1 : 0
  depends_on                            = [helm_release.prometheus_grafana, helm_release.grafana_mimir]
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "4.1.0"
  bucket                                = var.deployment_config.loki_scalable_config.s3_bucket_name
  force_destroy                         = var.loki_scalable_s3_bucket_force_destroy
  attach_deny_insecure_transport_policy = var.loki_scalable_s3_bucket_attach_deny_insecure_transport_policy

  versioning = {
    enabled = var.deployment_config.loki_scalable_config.versioning_enabled
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  # S3 bucket-level Public Access Block configuration
  block_public_acls       = var.loki_scalable_s3_bucket_block_public_acls
  block_public_policy     = var.loki_scalable_s3_bucket_block_public_policy
  ignore_public_acls      = var.loki_scalable_s3_bucket_ignore_public_acls
  restrict_public_buckets = var.loki_scalable_s3_bucket_restrict_public_buckets

  # S3 Bucket Ownership Controls
  object_ownership         = var.loki_scalable_s3_bucket_object_ownership
  control_object_ownership = var.loki_scalable_s3_bucket_control_object_ownership
}

resource "helm_release" "loki_scalable" {
  count = var.loki_scalable_enabled ? 1 : 0
  depends_on = [
    var.pgl_namespace,
    module.loki_scalable_s3_bucket,
    helm_release.prometheus_grafana
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
      s3_bucket_name            = module.loki_scalable_s3_bucket[0].s3_bucket_id,
      loki_scalable_s3_role_arn = aws_iam_role.loki_scalable_role[0].arn,
      s3_bucket_region          = var.deployment_config.loki_scalable_config.s3_bucket_region
    }),
    var.deployment_config.loki_scalable_config.loki_scalable_values
  ]
}

resource "helm_release" "promtail" {
  count = var.loki_scalable_enabled ? 1 : 0
  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.prometheus_grafana
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
