locals {
  name        = "grafana"
  region      = "eastus"
  environment = "dev"
  additional_tags = {
    Owner      = "organization_name"
    Expires    = "Never"
    Department = "Engineering"
  }
}

module "azure" {
  source                  = "https://github.com/sq-ia/terraform-kubernetes-grafana.git//modules/resources/azure"
  environment             = local.environment
  name                    = local.name
  resource_group_name     = ""
  resource_group_location = local.region
  aks_cluster_name        = ""
  aks_resource_group_name = ""
}

module "pgl" {
  source                        = "git@github.com:sq-ia/terraform-kubernetes-grafana.git"
  kube_prometheus_stack_enabled = false
  loki_enabled                  = true
  loki_scalable_enabled         = false
  grafana_mimir_enabled         = false
  cluster_name                  = ""
  # MIMER config
  bucket_provider_type          = "azure"
  azure_storage_account_name    = ""
  azure_container_name          = ""
  azure_storage_account_key     = ""
  az_service_account            = module.azure.azure_service_account
  deployment_config = {
    hostname                            = "grafanaa.az.skaf.squareops.in"
    storage_class_name                  = "infra-service-sc"
    prometheus_values_yaml              = file("./helm/prometheus.yaml")
    loki_values_yaml                    = file("./helm/loki.yaml")
    blackbox_values_yaml                = file("./helm/blackbox.yaml")
    grafana_mimir_values_yaml           = file("./helm/mimir.yaml")
    dashboard_refresh_interval          = ""
    grafana_enabled                     = true
    prometheus_hostname                 = "prometh.az.skaf.squareops.in"
    prometheus_internal_ingress_enabled = false
    loki_internal_ingress_enabled       = false
    loki_hostname                       = "lokii.az.skaf.squareops.in"
    promtail_config = {
      promtail_version = "6.8.2"
      promtail_values  = file("./helm/promtail.yaml")
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
    mysql            = true
    redis            = true
    argocd           = false
    consul           = false
    statsd           = false
    couchdb          = false
    jenkins          = true
    mongodb          = true
    pingdom          = false
    rabbitmq         = false
    blackbox         = false
    postgres         = true
    conntrack        = false
    cloudwatch       = false
    stackdriver      = false
    push_gateway     = false
    elasticsearch    = false
    prometheustosd   = false
    ethtool_exporter = false
  }
}
