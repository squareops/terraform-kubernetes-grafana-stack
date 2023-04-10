locals {
  region      = "us-east-2"
  name        = "skaf"
  environment = "prod"
}

module "pgl" {
  source                        = "../.."
  cluster_name                  = "cluster-name"
  kube_prometheus_stack_enabled = true
  loki_enabled                  = true
  grafana_mimir_enabled         = true
  deployment_config = {
    hostname                           = "grafanaa.squareops.in"
    storage_class_name                 = "gp2"
    prometheus_values_yaml             = file("./helm/prometheus.yaml")
    loki_values_yaml                   = file("./helm/loki.yaml")
    blackbox_values_yaml               = file("./helm/blackbox.yaml")
    grafana_mimir_values_yaml          = file("./helm/mimir.yaml")
    dashboard_refresh_interval         = "300"
    grafana_enabled                    = true
    prometheus_hostname                = ""
    enable_prometheus_internal_ingress = false
    enable_loki_internal_ingress       = false
    loki_hostname                      = ""
    mimir_s3_bucket_config = {
      s3_bucket_name     = ""
      versioning_enabled = "true"
      s3_bucket_region   = local.region
    }
    karpenter_enabled = true
    karpenter_config = {
      private_subnet_name                  = "private-subnet-name"
      karpenter_ec2_capacity_type          = ["spot"]
      excluded_karpenter_ec2_instance_type = ["nano", "micro", "small"]
      karpenter_values                     = file("./helm/karpenter.yaml")
    }
  }
  exporter_config = {
    argocd         = true
    blackbox       = true
    cloudwatch     = false
    conntrack      = false
    consul         = false
    couchdb        = false
    druid          = false
    elasticsearch  = false
    json           = false
    jenkins        = true
    kafka          = false
    mongodb        = true
    mysql          = true
    nats           = false
    nifi           = false
    pingdom        = false
    postgres       = false
    prometheustosd = false
    push_gateway   = false
    rabbitmq       = true
    redis          = true
    snmp           = false
    stackdriver    = false
    statsd         = false
  }


}
