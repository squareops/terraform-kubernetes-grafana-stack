locals {
  name           = "grafana"
  region         = "us-east-2"
  aws_account_id = ""
  environment    = "prod"
  additional_tags = {
    Owner      = "organization_name"
    Expires    = "Never"
    Department = "Engineering"
  }
}
module "pgl" {
  source                                     = "https://github.com/sq-ia/terraform-kubernetes-grafana.git"
  eks_cluster_name                           = ""
  aws_account_id                             = local.aws_account_id
  kube_prometheus_stack_enabled              = true
  loki_enabled                               = false
  loki_scalable_enabled                      = true
  grafana_mimir_enabled                      = true
  cloudwatch_enabled                         = true
  tempo_enabled                              = true
  mimir_s3_bucket_enable_object_lock         = true
  loki_scalable_s3_bucket_enable_object_lock = true
  tempo_s3_bucket_enable_object_lock         = true
  mimir_s3_bucket_lifecycle_rules = {
    default_rule = {
      status                            = false
      lifecycle_configuration_rule_name = "lifecycle_configuration_rule_name"
      expiration_days                   = 365
      enable_standard_ia_transition     = true
      standard_transition_days          = 40
    }
  }
  tempo_s3_bucket_lifecycle_rules = {
    default_rule = {
      status                            = false
      lifecycle_configuration_rule_name = "lifecycle_configuration_rule_name"
      expiration_days                   = 365
      enable_standard_ia_transition     = true
      standard_transition_days          = 40
    }
  }
  loki_scalable_s3_bucket_lifecycle_rules = {
    default_rule = {
      status                            = false
      lifecycle_configuration_rule_name = "lifecycle_configuration_rule_name"
      expiration_days                   = 365
      enable_standard_ia_transition     = true
      standard_transition_days          = 40
    }
  }
  deployment_config = {
    hostname                            = "grafana.dev.skaf.squareops.in"
    storage_class_name                  = "gp2"
    prometheus_values_yaml              = file("./helm/prometheus.yaml")
    loki_values_yaml                    = file("./helm/loki.yaml")
    blackbox_values_yaml                = file("./helm/blackbox.yaml")
    grafana_mimir_values_yaml           = file("./helm/mimir.yaml")
    tempo_values_yaml                   = file("./helm/tempo.yaml")
    dashboard_refresh_interval          = "10"
    grafana_enabled                     = true
    prometheus_hostname                 = "prometh.dev.skaf.squareops.in"
    prometheus_internal_ingress_enabled = true
    loki_internal_ingress_enabled       = true
    loki_hostname                       = "loki.dev.skaf.squareops.in"
    mimir_s3_bucket_config = {
      s3_bucket_name                    = "${local.environment}-${local.name}-mimir-s3-bucket"
      versioning_enabled                = "true"
      s3_bucket_region                  = local.region
      mimir_s3_bucket_object_lock_mode  = "GOVERNANCE"
      mimir_s3_bucket_object_lock_days  = "10"
      mimir_s3_bucket_object_lock_years = "0"
    }
    loki_scalable_config = {
      loki_scalable_version                     = "5.8.8"
      loki_scalable_values                      = file("./helm/loki-scalable.yaml")
      s3_bucket_name                            = "${local.environment}-${local.name}-loki-scalable-s3-bucket"
      versioning_enabled                        = "true"
      s3_bucket_region                          = local.region
      loki_scalable_s3_bucket_object_lock_mode  = "GOVERNANCE"
      loki_scalable_s3_bucket_object_lock_days  = "0"
      loki_scalable_s3_bucket_object_lock_years = "2"
    }
    promtail_config = {
      promtail_version = "6.8.2"
      promtail_values  = file("./helm/promtail.yaml")
    }
    tempo_config = {
      s3_bucket_name                    = "${local.environment}-${local.name}-tempo-bucket"
      versioning_enabled                = true
      s3_bucket_region                  = local.region
      tempo_s3_bucket_object_lock_mode  = "GOVERNANCE"
      tempo_s3_bucket_object_lock_days  = "50"
      tempo_s3_bucket_object_lock_years = "0"
    }
    otel_config = {
      otel_operator_enabled  = false
      otel_collector_enabled = false
    }
  }
  exporter_config = {
    json             = false
    nats             = false
    nifi             = false
    snmp             = false
    druid            = false
    istio            = true
    kafka            = false
    mysql            = true
    redis            = true
    argocd           = true
    consul           = false
    statsd           = false
    couchdb          = false
    jenkins          = true
    mongodb          = true
    pingdom          = false
    rabbitmq         = true
    blackbox         = true
    postgres         = false
    conntrack        = false
    stackdriver      = false
    push_gateway     = false
    elasticsearch    = false
    prometheustosd   = false
    ethtool_exporter = false
  }
}
