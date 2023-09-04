variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "environment" {
  description = "Environment in which the infrastructure is being deployed (e.g., production, staging, development)"
  type        = string
  default = "dev"
}

variable "GCP_GSA_NAME" {
  description = "Google Cloud Service Account name"
  type        = string
  default     = "mimir"
}

variable "GCP_KSA_NAME" {
  description = "Google Kubernetes Service Account name"
  type        = string
  default     = "grafana-mimir-sa"
}


variable "deployment_config" {
  type = any
  default = {
    hostname                            = ""
    storage_class_name                  = "gp2"
    prometheus_values_yaml              = ""
    loki_values_yaml                    = ""
    blackbox_values_yaml                = ""
    grafana_mimir_values_yaml           = ""
    dashboard_refresh_interval          = ""
    grafana_enabled                     = true
    prometheus_hostname                 = ""
    prometheus_internal_ingress_enabled = false
    loki_internal_ingress_enabled       = false
    loki_hostname                       = ""
    mimir_bucket_config = {
      versioning_enabled = ""
      s3_bucket_region   = ""
    }
    karpenter_enabled = true
    karpenter_config = {
      private_subnet_name    = ""
      instance_capacity_type = [""]
      excluded_instance_type = [""]
      karpenter_values       = ""
    }

  }
  description = "Configuration options for the Prometheus, Alertmanager, Loki, and Grafana deployments, including the hostname, storage class name, dashboard refresh interval, and S3 bucket configuration for Mimir."
}