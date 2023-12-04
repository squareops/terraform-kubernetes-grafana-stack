locals {
  name        = "grafana"
  region      = "us-east-2"
  environment = "dev"
  additional_tags = {
    Owner      = "organization_name"
    Expires    = "Never"
    Department = "Engineering"
  }
}

module "pgl" {
  source                        = "git@github.com:sq-ia/terraform-kubernetes-grafana.git"
  cluster_name                  = "cluster-name"
  kube_prometheus_stack_enabled = true
  loki_enabled                  = true
  loki_scalable_enabled         = false
  grafana_mimir_enabled         = false
  cloudwatch_enabled            = true
  tempo_enabled                 = true
  deployment_config = {
    hostname                            = "grafana.dev.skaf.squareops.in"
    storage_class_name                  = "gp2"
    prometheus_values_yaml              = file("./helm/prometheus.yaml")
    loki_values_yaml                    = file("./helm/loki.yaml")
    blackbox_values_yaml                = file("./helm/blackbox.yaml")
    grafana_mimir_values_yaml           = file("./helm/mimir.yaml")
    tempo_values_yaml                   = file("./helm/tempo.yaml")
    dashboard_refresh_interval          = ""
    grafana_enabled                     = true
    prometheus_hostname                 = "prometh.dev.skaf.squareops.in"
    prometheus_internal_ingress_enabled = false
    loki_internal_ingress_enabled       = false
    loki_hostname                       = "loki.dev.skaf.squareops.in"
    mimir_s3_bucket_config = {
      s3_bucket_name     = "${local.environment}-${local.name}-mimir-bucket"
      versioning_enabled = "false"
      s3_bucket_region   = local.region
      s3_object_expiration = 90
    }
    loki_scalable_config = {
      loki_scalable_version = "5.8.8"
      loki_scalable_values  = file("./helm/loki-scalable.yaml")
      s3_bucket_name        = "${local.environment}-${local.name}-loki-scalable-bucket"
      versioning_enabled    = "false"
      s3_bucket_region      = local.region
    }
    promtail_config = {
      promtail_version = "6.8.2"
      promtail_values  = file("./helm/promtail.yaml")
    }
    tempo_config = {
      s3_bucket_name   = "${local.environment}-${local.name}-tempo-skaf"
      versioning_enabled = false
      s3_bucket_region = local.region
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
    ethtool_exporter = true
  }
}
