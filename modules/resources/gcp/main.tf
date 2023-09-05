resource "google_service_account" "grafana_mimir" {
  project      = var.project_id
  account_id   = format("%s-%s", var.environment, var.GCP_GSA_NAME)
  display_name = "Service Account for External Secrets"
}

resource "google_project_iam_member" "secretadmin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.grafana_mimir.email}"
}

resource "google_project_iam_member" "service_account_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.grafana_mimir.email}"
}

resource "google_service_account_iam_member" "pod_identity" {
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/${var.GCP_KSA_NAME}]"
  service_account_id = google_service_account.grafana_mimir.name
}

module "gcs_buckets" {
  source     = "terraform-google-modules/cloud-storage/google"
  version    = "~> 4.0"
  project_id = var.project_id
  names      = [format("%s-%s", var.project_id, var.GCP_GSA_NAME)]
  prefix     = var.environment
  versioning = {
    format("%s-%s", var.project_id, var.GCP_GSA_NAME) = var.deployment_config.mimir_bucket_config.versioning_enabled
  }

}

output "bucket_name" {
  description = "Bucket name."
  value       = module.gcs_buckets.name
}

output "service_account" {
  value       = google_service_account.grafana_mimir.email
  description = "Service Account Name"
}
