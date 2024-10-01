locals {
  name        = ""
  region      = ""
  environment = ""
  additional_tags = {
    Owner      = "organization_name"
    Expires    = "Never"
    Department = "Engineering"
    Product    = ""
    Environment = local.environment
  }
}

module "pgl" {
  source                        = "git@github.com:sq-ia/terraform-kubernetes-grafana.git"
  cluster_name                  = ""
  kube_prometheus_stack_enabled = true
  loki_enabled                  = false
  loki_scalable_enabled         = true
  grafana_mimir_enabled         = true
  cloudwatch_enabled            = true
  tempo_enabled                 = false
  deployment_config = {
    hostname                            = "grafana.squareops.com"
    storage_class_name                  = "infra-service-sc"
    prometheus_values_yaml              = file("./helm/prometheus.yaml")
    loki_values_yaml                    = file("./helm/loki.yaml")
    blackbox_values_yaml                = file("./helm/blackbox.yaml")
    grafana_mimir_values_yaml           = file("./helm/mimir.yaml")
    tempo_values_yaml                   = file("./helm/tempo.yaml")
    dashboard_refresh_interval          = ""
    grafana_enabled                     = true
    prometheus_hostname                 = "prometheus.com"
    prometheus_internal_ingress_enabled = false
    grafana_ingress_load_balancer       = "nlb" ##Choose your load balancer type (e.g., NLB or ALB). If using ALB, ensure you provide the ACM certificate ARN for SSL.
    alb_acm_certificate_arn             = ""    #"arn:aws:acm:${local.region}:444455556666:certificate/certificate_ID"
    loki_internal_ingress_enabled       = false
    loki_hostname                       = "loki.com"
    mimir_s3_bucket_config = {
      s3_bucket_name       = "${local.environment}-${local.name}-mimir-bucket"
      versioning_enabled   = "false"
      s3_bucket_region     = "${local.region}"
      s3_object_expiration = 90
    }
    loki_scalable_config = {
      loki_scalable_version = "6.7.1"
      loki_scalable_values  = file("./helm/loki-scalable.yaml")
      s3_bucket_name        = "${local.environment}-${local.name}-loki-scalable-bucket"
      versioning_enabled    = "false"
      s3_bucket_region      = "${local.region}"
    }
    promtail_config = {
      promtail_version = "6.16.3"
      promtail_values  = file("./helm/promtail.yaml")
    }
    tempo_config = {
      s3_bucket_name       = "${local.environment}-${local.name}-tempo-skaf"
      versioning_enabled   = false
      s3_bucket_region     = "${local.region}"
      s3_object_expiration = "90"
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
    istio            = false
    kafka            = false
    mysql            = false
    redis            = false
    argocd           = false
    consul           = false
    statsd           = false
    couchdb          = false
    jenkins          = false
    mongodb          = false
    pingdom          = false
    rabbitmq         = false
    blackbox         = false
    postgres         = false
    conntrack        = false
    stackdriver      = false
    push_gateway     = false
    elasticsearch    = false
    prometheustosd   = false
    ethtool_exporter = false
  }
}
