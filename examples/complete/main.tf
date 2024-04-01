locals {
  name           = "grafana"
  region         = "ap-northeast-1"
  aws_account_id = "767398031518"
  environment    = "stg"
  additional_tags = {
    Owner      = "organization_name"
    Expires    = "Never"
    Department = "Engineering"
  }
  mimir_s3_bucket_lifecycle_rules = {
    rule1 = {
      id              = "rule1"
      expiration_days = 120
      filter_prefix   = "log/"
      status          = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 90
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    }
  }
  loki_scalable_s3_bucket_lifecycle_rules = {
    rule2 = {
      id              = "rule2"
      expiration_days = 120
      filter_prefix   = "log/"
      status          = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 90
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    }
  }
  tempo_s3_bucket_lifecycle_rules = {
    rule3 = {
      id              = "rule3"
      expiration_days = 120
      filter_prefix   = "log/"
      status          = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 90
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    }
  }
}
module "pgl" {
  source                                         = "https://github.com/sq-ia/terraform-kubernetes-grafana.git"
  cluster_name                                   = "stg-rachit"
  aws_account_id                                 = local.aws_account_id
  kube_prometheus_stack_enabled                  = true
  loki_enabled                                   = false
  loki_scalable_enabled                          = true
  grafana_mimir_enabled                          = true
  cloudwatch_enabled                             = true
  tempo_enabled                                  = true
  mimir_s3_bucket_lifecycle_rule_enabled         = true
  mimir_s3_bucket_lifecycle_rules                = local.mimir_s3_bucket_lifecycle_rules
  mimir_s3_bucket_object_lock_mode               = "GOVERNANCE"
  mimir_s3_bucket_object_lock_days               = "10"
  mimir_s3_bucket_object_lock_years              = "0"
  mimir_s3_bucket_enable_object_lock             = true
  loki_scalable_s3_bucket_lifecycle_rule_enabled = true
  loki_scalable_s3_bucket_lifecycle_rules        = local.loki_scalable_s3_bucket_lifecycle_rules
  loki_scalable_s3_bucket_object_lock_mode       = "GOVERNANCE"
  loki_scalable_s3_bucket_object_lock_days       = "10"
  loki_scalable_s3_bucket_object_lock_years      = "0"
  loki_scalable_s3_bucket_enable_object_lock     = true
  tempo_s3_bucket_lifecycle_rule_enabled         = true
  tempo_s3_bucket_lifecycle_rules                = local.tempo_s3_bucket_lifecycle_rules
  tempo_s3_bucket_object_lock_mode               = "GOVERNANCE"
  tempo_s3_bucket_object_lock_days               = "10"
  tempo_s3_bucket_object_lock_years              = "0"
  tempo_s3_bucket_enable_object_lock             = true

  deployment_config = {
    hostname                            = "grafana.test.atmosly.in"
    storage_class_name                  = "gp2"
    prometheus_values_yaml              = file("./helm/prometheus.yaml")
    loki_values_yaml                    = file("./helm/loki.yaml")
    blackbox_values_yaml                = file("./helm/blackbox.yaml")
    grafana_mimir_values_yaml           = file("./helm/mimir.yaml")
    tempo_values_yaml                   = file("./helm/tempo.yaml")
    dashboard_refresh_interval          = "10"
    grafana_enabled                     = true
    prometheus_hostname                 = "prometh.test.atmosly.in"
    prometheus_internal_ingress_enabled = true
    loki_internal_ingress_enabled       = true
    loki_hostname                       = "loki.test.atmosly.in"
    mimir_s3_bucket_config = {
      s3_bucket_name     = "${local.environment}-${local.name}-mimir-s3-bucket"
      versioning_enabled = "true"
      s3_bucket_region   = local.region
    }
    loki_scalable_config = {
      loki_scalable_version = "5.8.8"
      loki_scalable_values  = file("./helm/loki-scalable.yaml")
      s3_bucket_name        = "${local.environment}-${local.name}-loki-scalable-s3-bucket"
      versioning_enabled    = "true"
      s3_bucket_region      = local.region
    }
    promtail_config = {
      promtail_version = "6.8.2"
      promtail_values  = file("./helm/promtail.yaml")
    }
    tempo_config = {
      s3_bucket_name     = "${local.environment}-${local.name}-tempo-bucket"
      versioning_enabled = true
      s3_bucket_region   = local.region
    }
    otel_config = {
      otel_operator_enabled  = true
      otel_collector_enabled = true
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
