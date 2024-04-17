variable "aws_account_id" {
  description = "Account ID of the AWS Account."
  default     = ""
  type        = string
}

variable "kube_prometheus_stack_enabled" {
  default     = false
  type        = bool
  description = "Specify whether or not to deploy Grafana as part of the Prometheus and Alertmanager stack."
}

variable "loki_enabled" {
  default     = false
  type        = bool
  description = "Whether or not to deploy Loki for log aggregation and querying."
}

variable "loki_stack_version" {
  default     = "2.8.2"
  type        = string
  description = "Version of the Loki stack to deploy."
}

variable "blackbox_exporter_version" {
  default     = "4.10.1"
  type        = string
  description = "Version of the Blackbox exporter to deploy."
}

variable "prometheus_chart_version" {
  default     = "42.0.0"
  type        = string
  description = "Version of the Prometheus chart to deploy."
}

variable "grafana_mimir_version" {
  default     = "3.2.0"
  type        = string
  description = "Version of the Grafana Mimir plugin to deploy."
}


variable "grafana_mimir_enabled" {
  default     = false
  type        = bool
  description = "Specify whether or not to deploy the Grafana Mimir plugin."
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
    tempo_values_yaml                   = ""
    dashboard_refresh_interval          = ""
    grafana_enabled                     = true
    prometheus_hostname                 = ""
    prometheus_internal_ingress_enabled = false
    loki_internal_ingress_enabled       = false
    loki_hostname                       = ""
    mimir_s3_bucket_config = {
      s3_bucket_name                    = ""
      versioning_enabled                = ""
      s3_bucket_region                  = ""
      mimir_s3_bucket_object_lock_mode  = ""
      mimir_s3_bucket_object_lock_days  = ""
      mimir_s3_bucket_object_lock_years = ""
    }
    loki_scalable_config = {
      loki_scalable_version                     = "5.8.8"
      loki_scalable_values                      = ""
      s3_bucket_name                            = ""
      versioning_enabled                        = ""
      s3_bucket_region                          = ""
      loki_scalable_s3_bucket_object_lock_mode  = ""
      loki_scalable_s3_bucket_object_lock_days  = ""
      loki_scalable_s3_bucket_object_lock_years = ""
    }
    promtail_config = {
      promtail_version = "6.8.2"
      promtail_values  = ""
    }
    tempo_config = {
      s3_bucket_name                    = ""
      versioning_enabled                = false
      s3_bucket_region                  = ""
      tempo_s3_bucket_object_lock_mode  = ""
      tempo_s3_bucket_object_lock_days  = ""
      tempo_s3_bucket_object_lock_years = ""
    }
    otel_config = {
      otel_operator_enabled  = false
      otel_collector_enabled = false
    }
  }
  description = "Configuration options for the Prometheus, Alertmanager, Loki, and Grafana deployments, including the hostname, storage class name, dashboard refresh interval, and S3 bucket configuration for Mimir."
}

variable "exporter_config" {
  type = map(any)
  default = {
    blackbox         = true
    conntrack        = false
    consul           = false
    couchdb          = false
    druid            = false
    elasticsearch    = true
    json             = false
    kafka            = false
    mongodb          = true
    mysql            = true
    nats             = false
    nifi             = false
    istio            = false
    pingdom          = false
    postgres         = false
    prometheustosd   = false
    ethtool_exporter = true
    push_gateway     = false
    rabbitmq         = false
    redis            = true
    snmp             = false
    stackdriver      = false
    statsd           = true
    jenkins          = false
    argocd           = false
  }
  description = "allows enabling/disabling various exporters for scraping metrics, including Consul, MongoDB, Redis, and StatsD."
}

variable "pgl_namespace" {
  default     = "monitoring"
  type        = string
  description = "Name of the Kubernetes namespace where the Grafana deployment will be deployed."
}

variable "cloudwatch_enabled" {
  default     = false
  type        = bool
  description = "Whether or not to add CloudWatch as datasource and add some default dashboards for AWS in Grafana."
}


variable "eks_cluster_name" {
  type        = string
  description = "Specifies the name of the EKS cluster."
}

###
variable "loki_scalable_enabled" {
  default     = false
  type        = bool
  description = "Specify whether or not to deploy the loki scalable"
}

variable "tempo_enabled" {
  type        = bool
  default     = false
  description = "Enable Grafana Tempo"
}

variable "mimir_s3_bucket_block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "mimir_s3_bucket_block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket.	"
  default     = true
  type        = bool
}

variable "mimir_s3_bucket_ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "mimir_s3_bucket_restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket."
  default     = true
  type        = bool
}

variable "mimir_s3_bucket_attach_deny_insecure_transport_policy" {
  description = "Whether to attach a policy that denies requests made over insecure transport protocols to the S3 bucket."
  default     = true
  type        = bool
}

variable "mimir_s3_bucket_force_destroy" {
  description = "Whether or not to delete all objects from the bucket to allow for destruction of the bucket without error."
  default     = true
  type        = bool
}

variable "mimir_s3_bucket_object_ownership" {
  description = "Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter."
  default     = "BucketOwnerPreferred"
  type        = string
}

variable "mimir_s3_bucket_control_object_ownership" {
  description = "Whether to manage S3 Bucket Ownership Controls on this bucket."
  default     = true
  type        = bool
}


variable "loki_scalable_s3_bucket_block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "loki_scalable_s3_bucket_block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket.	"
  default     = true
  type        = bool
}

variable "loki_scalable_s3_bucket_ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "loki_scalable_s3_bucket_restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket."
  default     = true
  type        = bool
}

variable "loki_scalable_s3_bucket_attach_deny_insecure_transport_policy" {
  description = "Whether to attach a policy that denies requests made over insecure transport protocols to the S3 bucket."
  default     = true
  type        = bool
}

variable "loki_scalable_s3_bucket_force_destroy" {
  description = "Whether or not to delete all objects from the bucket to allow for destruction of the bucket without error."
  default     = true
  type        = bool
}

variable "loki_scalable_s3_bucket_object_ownership" {
  description = "Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter."
  default     = "BucketOwnerPreferred"
  type        = string
}

variable "loki_scalable_s3_bucket_control_object_ownership" {
  description = "Whether to manage S3 Bucket Ownership Controls on this bucket."
  default     = true
  type        = bool
}

variable "tempo_s3_bucket_block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "tempo_s3_bucket_block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket.	"
  default     = true
  type        = bool
}

variable "tempo_s3_bucket_ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "tempo_s3_bucket_restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket."
  default     = true
  type        = bool
}

variable "tempo_s3_bucket_attach_deny_insecure_transport_policy" {
  description = "Whether to attach a policy that denies requests made over insecure transport protocols to the S3 bucket."
  default     = true
  type        = bool
}

variable "tempo_s3_bucket_force_destroy" {
  description = "Whether or not to delete all objects from the bucket to allow for destruction of the bucket without error."
  default     = true
  type        = bool
}

variable "tempo_s3_bucket_object_ownership" {
  description = "Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter."
  default     = "BucketOwnerPreferred"
  type        = string
}

variable "tempo_s3_bucket_control_object_ownership" {
  description = "Whether to manage S3 Bucket Ownership Controls on this bucket."
  default     = true
  type        = bool
}

variable "mimir_s3_bucket_enable_object_lock" {
  description = "Whether to enable object lock in mimir S3 bucket."
  type        = bool
  default     = true
}

variable "tempo_s3_bucket_enable_object_lock" {
  description = "Whether to enable object lock for tempo S3 bucket."
  type        = bool
  default     = true
}

variable "loki_scalable_s3_bucket_enable_object_lock" {
  description = "Whether to enable object lock for loki-scalable S3 bucket."
  type        = bool
  default     = true
}

variable "tempo_s3_bucket_lifecycle_rules" {
  description = "A map of lifecycle rules for tempo AWS S3 bucket."
  type = map(object({
    status                            = bool
    lifecycle_configuration_rule_name = string
    enable_glacier_transition         = optional(bool, false)
    enable_deeparchive_transition     = optional(bool, false)
    enable_standard_ia_transition     = optional(bool, false)
    enable_one_zone_ia                = optional(bool, false)
    enable_current_object_expiration  = optional(bool, false)
    enable_intelligent_tiering        = optional(bool, false)
    enable_glacier_ir                 = optional(bool, false)
    standard_transition_days          = optional(number, 30)
    glacier_transition_days           = optional(number, 60)
    deeparchive_transition_days       = optional(number, 150)
    one_zone_ia_days                  = optional(number, 40)
    intelligent_tiering_days          = optional(number, 50)
    glacier_ir_days                   = optional(number, 160)
    expiration_days                   = optional(number, 365)
  }))
  default = {
    default_rule = {
      status                            = false
      lifecycle_configuration_rule_name = "lifecycle_configuration_rule_name"
    }
  }
}

variable "mimir_s3_bucket_lifecycle_rules" {
  description = "A map of lifecycle rules for mimir AWS S3 bucket."
  type = map(object({
    status                            = bool
    lifecycle_configuration_rule_name = string
    enable_glacier_transition         = optional(bool, false)
    enable_deeparchive_transition     = optional(bool, false)
    enable_standard_ia_transition     = optional(bool, false)
    enable_one_zone_ia                = optional(bool, false)
    enable_current_object_expiration  = optional(bool, false)
    enable_intelligent_tiering        = optional(bool, false)
    enable_glacier_ir                 = optional(bool, false)
    standard_transition_days          = optional(number, 30)
    glacier_transition_days           = optional(number, 60)
    deeparchive_transition_days       = optional(number, 150)
    one_zone_ia_days                  = optional(number, 40)
    intelligent_tiering_days          = optional(number, 50)
    glacier_ir_days                   = optional(number, 160)
    expiration_days                   = optional(number, 365)
  }))
  default = {
    default_rule = {
      status                            = false
      lifecycle_configuration_rule_name = "lifecycle_configuration_rule_name"
    }
  }
}

variable "loki_scalable_s3_bucket_lifecycle_rules" {
  description = "A map of lifecycle rules for loki-scalable AWS S3 bucket."
  type = map(object({
    status                            = bool
    lifecycle_configuration_rule_name = string
    enable_glacier_transition         = optional(bool, false)
    enable_deeparchive_transition     = optional(bool, false)
    enable_standard_ia_transition     = optional(bool, false)
    enable_one_zone_ia                = optional(bool, false)
    enable_current_object_expiration  = optional(bool, false)
    enable_intelligent_tiering        = optional(bool, false)
    enable_glacier_ir                 = optional(bool, false)
    standard_transition_days          = optional(number, 30)
    glacier_transition_days           = optional(number, 60)
    deeparchive_transition_days       = optional(number, 150)
    one_zone_ia_days                  = optional(number, 40)
    intelligent_tiering_days          = optional(number, 50)
    glacier_ir_days                   = optional(number, 160)
    expiration_days                   = optional(number, 365)
  }))
  default = {
    default_rule = {
      status                            = false
      lifecycle_configuration_rule_name = "lifecycle_configuration_rule_name"
    }
  }
}
