locals {
  oidc_provider = replace(
    data.aws_eks_cluster.kubernetes_cluster.identity[0].oidc[0].issuer,
    "/^https:///",
    ""
  )
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "kubernetes_cluster" {
  name = var.cluster_name
}

resource "aws_iam_role" "mimir_role" {
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
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "3.7.0"
  bucket                                = format("%s-%s-mimir", data.aws_caller_identity.current.account_id, var.cluster_name)
  force_destroy                         = true
  attach_deny_insecure_transport_policy = false
  versioning = {
    enabled = var.s3_versioning
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
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

  # S3 Bucket Ownership Controls
  object_ownership         = "BucketOwnerPreferred"
  control_object_ownership = true
}

resource "aws_iam_role" "loki_scalable_role" {
  count      = var.loki_scalable_enabled ? 1 : 0
  name       = join("-", [var.cluster_name, "loki-scalable"])
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

output "loki_scalable_role" {
    value = aws_iam_role.loki_scalable_role  
}

output "role_arn" {
  value = aws_iam_role.mimir_role.arn
}
 
output "s3_bucket" {
  value = module.s3_bucket_mimir.s3_bucket_id
}