## MONITORING

variable "kube_prometheus_stack_enabled" {
  default     = false
  type        = bool
  description = "Set true to deploy grafana"
}

variable "loki_enabled" {
  default     = false
  type        = bool
  description = "Set true to deploy loki"
}

variable "loki_stack_version" {
  default     = "2.8.2"
  type        = string
  description = "Enter loki stack Version"
}

variable "blackbox_exporter_version" {
  default     = "4.10.1"
  type        = string
  description = "Enter Blackbox exporter version"
}

variable "prometheus_chart_version" {
  default     = "42.0.0"
  type        = string
  description = "Enter prometheus_chart_version"
}

variable "grafana_mimir_version" {
  default     = "3.2.0"
  type        = string
  description = "Enter grafana mimir version"
}


variable "grafana_mimir_enabled" {
  default     = false
  type        = bool
  description = "Set true to grafana mimir"
}

variable "deployment_config" {
  type = any
  default = {
    hostname                           = ""
    storage_class_name                 = "gp2"
    prometheus_values_yaml             = ""
    loki_values_yaml                   = ""
    blackbox_values_yaml               = ""
    grafana_mimir_values_yaml          = ""
    dashboard_refresh_interval         = ""
    grafana_enabled                    = true
    prometheus_hostname                = ""
    enable_prometheus_internal_ingress = false
    enable_loki_internal_ingress       = false
    loki_hostname                      = ""
    mimir_s3_bucket_config = {
      s3_bucket_name     = ""
      versioning_enabled = ""
      s3_bucket_region   = ""
    }
    karpenter_enabled = ""
    karpenter_config = {
      private_subnet_name                  = ""
      karpenter_ec2_capacity_type          = [""]
      excluded_karpenter_ec2_instance_type = [""]
      karpenter_values                     = ""
    }

  }
  description = "PGL configurations"
}

variable "exporter_config" {
  type = map(any)
  default = {
    blackbox       = true
    cloudwatch     = false
    conntrack      = false
    consul         = false
    couchdb        = false
    druid          = false
    elasticsearch  = true
    json           = false
    kafka          = false
    mongodb        = true
    mysql          = true
    nats           = false
    nifi           = false
    pingdom        = false
    postgres       = false
    prometheustosd = false
    push_gateway   = false
    rabbitmq       = false
    redis          = true
    snmp           = false
    stackdriver    = false
    statsd         = true
    jenkins        = false
    argocd         = false
  }
}

variable "pgl_namespace" {
  default = "monitoring"
  type    = string
}

variable "aws_cw_secret" {
  default     = false
  type        = bool
  description = "Set to true if want to create kubernetes secret for cloudwatch exporter"
}

variable "aws_access_key_id" {
  default     = ""
  type        = string
  description = "provide aws access key for creating the cloudwatch secret"
}

variable "aws_secret_key_id" {
  default     = ""
  type        = string
  description = "provide aws secret key for creating the cloudwatch secret"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}
