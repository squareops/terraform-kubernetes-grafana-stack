locals {
  name        = "sonarqube"
  region      = "us-east-2"
  environment = "prod"
  additional_tags = {
    Owner      = "organization_name"
    Expires    = "Never"
    Department = "Engineering"
  }
}

module "pgl" {
  source                        = "https://github.com/sq-ia/terraform-kubernetes-grafana.git"
  cluster_name                  = "cluster-name"
  kube_prometheus_stack_enabled = true
  loki_enabled                  = true
  loki_scalable_enabled         = false
  grafana_mimir_enabled         = true
  deployment_config = {
    hostname                            = "grafanaa.squareops.in"
    storage_class_name                  = "gp2"
    prometheus_values_yaml              = file("./helm/prometheus.yaml")
    loki_values_yaml                    = file("./helm/loki.yaml")
    blackbox_values_yaml                = file("./helm/blackbox.yaml")
    grafana_mimir_values_yaml           = file("./helm/mimir.yaml")
    dashboard_refresh_interval          = "300"
    grafana_enabled                     = true
    prometheus_hostname                 = "prometh.squareops.in"
    prometheus_internal_ingress_enabled = false
    loki_internal_ingress_enabled       = false
    loki_hostname                       = "loki.squareops.in"
    mimir_s3_bucket_config = {
      s3_bucket_name     = ""
      versioning_enabled = "true"
      s3_bucket_region   = local.region
    }
    loki_scalable_config = {
      loki_scalable_version = "5.8.8"
      loki_scalable_values  = file("./helm/loki-scalable.yaml")
      s3_bucket_name        = ""
      versioning_enabled    = true
      s3_bucket_region      = "local.region"
    }
    promtail_config = {
      promtail_version = "6.8.2"
      promtail_values  = file("./helm/promtail.yaml")
    }
    karpenter_enabled = true
    karpenter_config = {
      private_subnet_name    = "private-subnet-name"
      instance_capacity_type = ["spot"]
      excluded_instance_type = ["nano", "micro", "small"]
      karpenter_values       = file("./helm/karpenter.yaml")
    }
  }
  exporter_config = {
    json           = false
    nats           = false
    nifi           = false
    snmp           = false
    kafka          = false
    druid          = false
    mysql          = true
    redis          = true
    consul         = false
    argocd         = true
    statsd         = false
    couchdb        = false
    jenkins        = true
    istio          = true
    mongodb        = true
    pingdom        = false
    blackbox       = true
    rabbitmq       = true
    postgres       = false
    conntrack      = false
    cloudwatch     = false
    stackdriver    = false
    push_gateway   = false
    elasticsearch  = false
    prometheustosd = false
  }
}
