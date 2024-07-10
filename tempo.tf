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
  name  = join("-", [var.cluster_name, "tempo"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
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

module "s3_bucket_temp" {
  count                                 = var.tempo_enabled ? 1 : 0
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "4.1.2"
  bucket                                = var.deployment_config.tempo_config.s3_bucket_name
  force_destroy                         = true
  attach_deny_insecure_transport_policy = true
  versioning = {
    enabled = var.deployment_config.tempo_config.versioning_enabled
  }

  lifecycle_rule = [
    {
      id      = "tempo_s3"
      enabled = true
      expiration = {
        days = var.deployment_config.tempo_config.s3_object_expiration
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
