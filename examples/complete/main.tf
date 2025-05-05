locals {
  name        = "alloy"
  region      = "us-east-1"
  environment = "test"
  additional_tags = {
    Owner       = "organization_name"
    Expires     = "Never"
    Department  = "Engineering"
    Product     = "alloy"
    Environment = local.environment
  }
}

module "pgl" {
  source                        = "squareops/grafana-stack/kubernetes"
  version                       = "3.1.0"
  cluster_name                  = ""
  kube_prometheus_stack_enabled = true
  loki_enabled                  = true
  grafana_alloy_enabled         = true
  loki_scalable_enabled         = false
  grafana_mimir_enabled         = false
  cloudwatch_enabled            = true
  tempo_enabled                 = false
  deployment_config = {
    hostname                            = "grafana-alloy.rnd.squareops.in"
    storage_class_name                  = "infra-service-sc"
    prometheus_values_yaml              = file("./helm/prometheus.yaml")
    loki_values_yaml                    = file("./helm/loki.yaml")
    alloy_values_yaml                   = file("./helm/alloy-values.yaml")
    blackbox_values_yaml                = file("./helm/blackbox.yaml")
    grafana_mimir_values_yaml           = file("./helm/mimir.yaml")
    tempo_values_yaml                   = file("./helm/tempo.yaml")
    dashboard_refresh_interval          = "120s"
    grafana_enabled                     = true
    prometheus_hostname                 = "prometheus-alloy.rnd.squareops.in"
    prometheus_internal_ingress_enabled = false
    grafana_ingress_load_balancer       = "nlb"   ##Choose your load balancer type (e.g., NLB or ALB). If using ALB, ensure you provide the ACM certificate ARN for SSL.
    ingress_class_name                  = "nginx" # enter ingress class name according to your requirement (example: "nginx", "internal-ingress", "private-nginx")
    alb_acm_certificate_arn             = ""      #"arn:aws:acm:${local.region}:444455556666:certificate/certificate_ID"
    private_alb_enabled                 = false   # Set to true, when wanted to deploy PGL on ALB internal
    loki_internal_ingress_enabled       = false
    loki_hostname                       = "loki-alloy.rnd.squareops.in"
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
    alloy_config = {
      alloy_values = file("./helm/alloy-values.yaml")
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
