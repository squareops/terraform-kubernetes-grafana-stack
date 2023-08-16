resource "aws_iam_role" "loki_scalable_role" {
  count = var.loki_scalable_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana, helm_release.grafana_mimir]
  name  = join("-", [var.cluster_name, "loki-scalable"])
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
            "${local.oidc_provider}:sub" = "system:serviceaccount:monitoring:loki-canary"
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

module "loki_scalable_s3_bucket" {
  count                                 = var.loki_scalable_enabled ? 1 : 0
  depends_on                            = [helm_release.prometheus_grafana, helm_release.grafana_mimir]
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "3.7.0"
  bucket                                = var.deployment_config.loki_scalable_config.s3_bucket_name
  force_destroy                         = true
  attach_deny_insecure_transport_policy = false

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
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Bucket Ownership Controls
  object_ownership         = "BucketOwnerPreferred"
  control_object_ownership = true
}

resource "helm_release" "loki_scalable" {
  count = var.loki_scalable_enabled ? 1 : 0
  depends_on = [
    kubernetes_namespace.monitoring,
    module.loki_scalable_s3_bucket,
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
