output "loki_scalable_role" {
  description = "IAM role for loki scalable bucket"
  value       = aws_iam_role.loki_scalable_role
}

output "role_arn" {
  description = "IAM role arn of the loki scalable role"
  value       = aws_iam_role.mimir_role.arn
}

output "s3_bucket" {
  description = "The AWS S3 bucket name"
  value       = module.s3_bucket_mimir.s3_bucket_id
}