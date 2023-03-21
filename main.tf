locals {
  oidc_provider = replace(
    data.aws_eks_cluster.kubernetes_cluster.identity[0].oidc[0].issuer,
    "/^https:///",
    ""
  )
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "kubernetes_cluster" {
  name = var.cluster_name
}


resource "random_password" "grafana_password" {
  length  = 20
  special = false
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.pgl_namespace
  }
}
resource "helm_release" "loki" {
  count           = var.loki_enabled ? 1 : 0
  depends_on      = [kubernetes_namespace.monitoring]
  name            = "loki"
  namespace       = var.pgl_namespace
  atomic          = true
  cleanup_on_fail = true
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "loki-stack"
  version         = var.loki_stack_version
  values = [
    templatefile("${path.module}/helm/values/loki/values.yaml", {
      loki_hostname                = var.deployment_config.loki_hostname,
      enable_loki_internal_ingress = var.deployment_config.enable_loki_internal_ingress
    }),
    var.deployment_config.loki_values_yaml
  ]
}

resource "helm_release" "blackbox_exporter" {
  count      = var.exporter_config.blackbox ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]

  name       = "blackbox-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  namespace  = var.pgl_namespace
  version    = var.blackbox_exporter_version
  timeout    = 600

  values = [
    file("${path.module}/helm/values/blackbox_exporter/values.yaml"),
    var.deployment_config.blackbox_values_yaml
  ]
}

resource "helm_release" "prometheus_grafana" {
  depends_on        = [kubernetes_namespace.monitoring, kubernetes_priority_class.priority_class]
  name              = "prometheus-operator"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "kube-prometheus-stack"
  namespace         = var.pgl_namespace
  dependency_update = true
  version           = var.prometheus_chart_version
  timeout           = 600
  values = var.grafana_mimir_enabled ? [
    templatefile("${path.module}/helm/values/prometheus/mimir/values.yaml", {
      hostname               = "${var.deployment_config.hostname}",
      grafana_admin_password = "${random_password.grafana_password.result}",
      storage_class_name     = "${var.deployment_config.storage_class_name}",
      min_refresh_interval   = "${var.deployment_config.dashboard_refresh_interval}",
      grafana_enabled        = "${var.deployment_config.grafana_enabled}"
    }),
    var.deployment_config.prometheus_values_yaml
    ] : [
    templatefile("${path.module}/helm/values/prometheus/values.yaml", {
      hostname                           = "${var.deployment_config.hostname}",
      grafana_admin_password             = "${random_password.grafana_password.result}",
      storage_class_name                 = "${var.deployment_config.storage_class_name}",
      min_refresh_interval               = "${var.deployment_config.dashboard_refresh_interval}",
      grafana_enabled                    = "${var.deployment_config.grafana_enabled}",
      enable_prometheus_internal_ingress = "${var.deployment_config.enable_prometheus_internal_ingress}",
      prometheus_hostname                = "${var.deployment_config.prometheus_hostname}"
    }),
    var.deployment_config.prometheus_values_yaml
  ]
}

resource "helm_release" "karpenter_provisioner" {
  count   = var.deployment_config.karpenter_enabled ? 1 : 0
  name    = "karpenter-provisioner-pgl"
  chart   = "${path.module}/karpenter_provisioner/"
  timeout = 600
  values = [
    templatefile("${path.module}/karpenter_provisioner/values.yaml", {
      private_subnet_name                  = var.deployment_config.karpenter_config.private_subnet_name,
      cluster_name                         = var.cluster_name,
      karpenter_ec2_capacity_type          = "[${join(",", [for s in var.deployment_config.karpenter_config.karpenter_ec2_capacity_type : format("%s", s)])}]",
      excluded_karpenter_ec2_instance_type = "[${join(",", var.deployment_config.karpenter_config.excluded_karpenter_ec2_instance_type)}]"
    }),
    var.deployment_config.karpenter_config.karpenter_values
  ]
}

resource "kubernetes_priority_class" "priority_class" {
  description = "Used for grafana critical pods that must not be moved from their current"
  metadata {
    name = "grafana-pod-critical"
  }
  global_default    = false
  preemption_policy = "PreemptLowerPriority"
  value             = 1000000000
}

resource "kubernetes_secret" "cloudwatch_cred" {
  metadata {
    name      = "cloudwatch-secret"
    namespace = var.pgl_namespace
  }
  data = {
    access_key = var.aws_access_key_id
    secret_key = var.aws_secret_key_id
  }
  type       = "Opaque"
  count      = var.aws_cw_secret ? 1 : 0
  depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "cloudwatch_exporter" {
  count      = var.exporter_config.cloudwatch ? 1 : 0
  name       = "cloudwatch-operator"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-cloudwatch-exporter"
  namespace  = var.pgl_namespace
  version    = "0.19.2"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/cloudwatch.yaml")
  ]
  depends_on = [
    kubernetes_secret.cloudwatch_cred,
    helm_release.prometheus_grafana
  ]
}

resource "helm_release" "conntrak_stats_exporter" {
  count      = var.exporter_config.conntrack ? 1 : 0
  name       = "conntrack-stats-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-conntrack-stats-exporter"
  namespace  = var.pgl_namespace
  version    = "0.1.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/conntrack.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "consul_exporter" {
  count      = var.exporter_config.consul ? 1 : 0
  name       = "consul-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-consul-exporter"
  namespace  = var.pgl_namespace
  version    = "0.5.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/consul.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "couchdb_exporter" {
  count      = var.exporter_config.couchdb ? 1 : 0
  name       = "couchdb-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-couchdb-exporter"
  namespace  = var.pgl_namespace
  version    = "0.2.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/couchdb.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "druid_exporter" {
  count      = var.exporter_config.druid ? 1 : 0
  name       = "druid-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-druid-exporter"
  namespace  = var.pgl_namespace
  version    = "0.11.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/druid.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "elasticsearch_exporter" {
  count      = var.exporter_config.elasticsearch ? 1 : 0
  name       = "elasticsearch-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-elasticsearch-exporter"
  namespace  = var.pgl_namespace
  version    = "4.13.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/elasticsearch-exporter.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "json_exporter" {
  count      = var.exporter_config.json ? 1 : 0
  name       = "json-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-json-exporter"
  namespace  = var.pgl_namespace
  version    = "0.2.3"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/json-exporter.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "kafka_exporter" {
  count      = var.exporter_config.kafka ? 1 : 0
  name       = "kafka-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-kafka-exporter"
  namespace  = var.pgl_namespace
  version    = "1.6.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/kafka.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

# resource "helm_release" "mongodb_exporter" {
#   count             = var.exporter_config.mongodb ? 1 : 0
#   name              = "mongodb-exporter"
#   repository        = "https://prometheus-community.github.io/helm-charts"
#   chart             = "prometheus-mongodb-exporter"
#   namespace         = var.pgl_namespace
#   version           = "3.1.0"
#   timeout           = 600
#   values = [
#     file("${path.module}/helm/values/mongodb.yaml")
#   ]
#   depends_on = [helm_release.prometheus_grafana]
# }

# resource "helm_release" "mysql_exporter" {
#   count             = var.exporter_config.mysql ? 1 : 0
#   name              = "mysql-exporter"
#   repository        = "https://prometheus-community.github.io/helm-charts"
#   chart             = "prometheus-mysql-exporter"
#   namespace         = var.pgl_namespace
#   version           = "1.8.1"
#   timeout           = 600
#   values = [
#     file("${path.module}/helm/values/mysql.yaml")
#   ]
#   depends_on = [helm_release.prometheus_grafana]
# }

resource "helm_release" "nats_exporter" {
  count      = var.exporter_config.nats ? 1 : 0
  name       = "nats-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-nats-exporter"
  namespace  = var.pgl_namespace
  version    = "2.9.3"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/nats.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "pingdom_exporter" {
  count      = var.exporter_config.pingdom ? 1 : 0
  name       = "pingdom-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-pingdom-exporter"
  namespace  = var.pgl_namespace
  version    = "2.4.1"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/pingdom.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "postgres_exporter" {
  count      = var.exporter_config.postgres ? 1 : 0
  name       = "postgres-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-postgres-exporter"
  namespace  = var.pgl_namespace
  version    = "3.0.3"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/postgres.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "pushgateway" {
  count      = var.exporter_config.push_gateway ? 1 : 0
  name       = "pushgateway"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-pushgateway"
  namespace  = var.pgl_namespace
  version    = "1.18.2"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/pushgateway.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

# resource "helm_release" "rabbitmq_exporter" {
#   count             = var.exporter_config.rabbitmq ? 1 : 0
#   name              = "rabbitmq-exporter"
#   repository        = "https://prometheus-community.github.io/helm-charts"
#   chart             = "prometheus-rabbitmq-exporter"
#   namespace         = var.pgl_namespace
#   version           = "1.3.0"
#   timeout           = 600
#   values = [
#     file("${path.module}/helm/values/rabbitmq.yaml")
#   ]
#   depends_on = [helm_release.prometheus_grafana]
# }

# resource "helm_release" "redis_exporter" {
#   count             = var.exporter_config.redis ? 1 : 0
#   name              = "redis-exporter"
#   repository        = "https://prometheus-community.github.io/helm-charts"
#   chart             = "prometheus-redis-exporter"
#   namespace         = var.pgl_namespace
#   version           = "5.0.0"
#   timeout           = 600
#   values = [
#     file("${path.module}/helm/values/redis.yaml")
#   ]
#   depends_on = [helm_release.prometheus_grafana]
# }

resource "helm_release" "snmp_exporter" {
  count      = var.exporter_config.snmp ? 1 : 0
  name       = "snmp-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-snmp-exporter"
  namespace  = var.pgl_namespace
  version    = "1.1.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/snmp.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "stackdriver_exporter" {
  count      = var.exporter_config.stackdriver ? 1 : 0
  name       = "stackdriver-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-stackdriver-exporter"
  namespace  = var.pgl_namespace
  version    = "4.0.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/stackdriver.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "statsd_exporter" {
  count      = var.exporter_config.statsd ? 1 : 0
  name       = "statsd-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-statsd-exporter"
  namespace  = var.pgl_namespace
  version    = "0.5.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/statsd.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "prometheus-to-sd" {
  count      = var.exporter_config.prometheustosd ? 1 : 0
  name       = "prometheus-to-sd"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-to-sd"
  namespace  = var.pgl_namespace
  version    = "0.4.0"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/prometheus-to-sd.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "cluster_overview_dashboard" {
  count = var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "prometheus-operator-kube-p-cluster-overview"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "cluster-overview.json" = "${file("${path.module}/grafana/dashboards/cluster_overview.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "ingress_nginx_dashboard" {
  count      = var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]
  metadata {
    name      = "prometheus-operator-kube-p-ingress-nginx"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "ingress-nginx.json" = "${file("${path.module}/grafana/dashboards/ingress_nginx.json")}"
  }
}

resource "kubernetes_config_map" "nifi_dashboard" {
  depends_on = [helm_release.prometheus_grafana]
  count      = var.exporter_config.nifi && var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "prometheus-operator-kube-p-nifi-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "nifi-metrics.json" = "${file("${path.module}/grafana/dashboards/nifi_metrics.json")}"
  }
}

resource "kubernetes_config_map" "blackbox_dashboard" {
  depends_on = [helm_release.prometheus_grafana]
  count      = var.exporter_config.blackbox && var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "prometheus-operator-kube-p-blackbox-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "blackbox-dashboard.json" = "${file("${path.module}/grafana/dashboards/blackbox_exporter.json")}"
  }
}

resource "kubernetes_config_map" "mongodb_dashboard" {
  depends_on = [helm_release.prometheus_grafana]
  count      = var.exporter_config.mongodb && var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "prometheus-operator-kube-p-mongodb-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mongodb-dashboard.json" = "${file("${path.module}/grafana/dashboards/mongodb.json")}"
  }
}

resource "kubernetes_config_map" "mysql_dashboard" {
  count      = var.exporter_config.mysql && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]
  metadata {
    name      = "prometheus-operator-kube-p-mysql-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "mysql-dashboard.json" = "${file("${path.module}/grafana/dashboards/mysql.json")}"
  }
}

resource "kubernetes_config_map" "postgres_dashboard" {
  count      = var.exporter_config.postgres && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]
  metadata {
    name      = "prometheus-operator-kube-p-postgres-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "postgresql-dashboard.json" = "${file("${path.module}/grafana/dashboards/postgresql.json")}"
  }
}

resource "kubernetes_config_map" "redis_dashboard" {
  count      = var.exporter_config.redis && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]
  metadata {
    name      = "prometheus-operator-kube-p-redis-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "redis-dashboard.json" = "${file("${path.module}/grafana/dashboards/redis.json")}"
  }
}

resource "kubernetes_config_map" "rabbitmq_dashboard" {
  count      = var.exporter_config.rabbitmq && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]
  metadata {
    name      = "prometheus-operator-kube-p-rabbitmq-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "rabbitmq-dashboard.json" = "${file("${path.module}/grafana/dashboards/rabbitmq.json")}"
  }
}

resource "kubernetes_config_map" "loki_dashboard" {
  count = var.loki_enabled && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.prometheus_grafana,
    helm_release.loki
  ]
  metadata {
    name      = "prometheus-operator-kube-p-loki-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "loki-dashboard.json" = "${file("${path.module}/grafana/dashboards/loki.json")}"
  }
}

resource "kubernetes_config_map" "nodegroup_dashboard" {
  count = var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.prometheus_grafana
  ]
  metadata {
    name      = "prometheus-operator-kube-p-nodegroup-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "nodegroup-dashboard.json" = "${file("${path.module}/grafana/dashboards/nodegroup.json")}"
  }
}

resource "kubernetes_config_map" "jenkins_dashboard" {
  count = var.exporter_config.jenkins && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.prometheus_grafana
  ]
  metadata {
    name      = "prometheus-operator-kube-p-jenkins-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "jenkins-dashboard.json" = "${file("${path.module}/grafana/dashboards/jenkins.json")}"
  }
}

resource "kubernetes_config_map" "argocd_dashboard" {
  count = var.exporter_config.argocd && var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.prometheus_grafana
  ]
  metadata {
    name      = "prometheus-operator-kube-p-argocd-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "argocd-dashboard.json" = "${file("${path.module}/grafana/dashboards/argocd.json")}"
  }
}

resource "kubernetes_config_map" "grafana_home_dashboard" {
  count = var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [
    helm_release.prometheus_grafana
  ]
  metadata {
    name      = "grafana-home-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-35.2.0"
      "release" : "prometheus-operator"
    }
  }

  data = {
    "grafana-home-dashboard.json" = "${file("${path.module}/grafana/dashboards/grafana_home_dashboard.json")}"
  }
}

data "kubernetes_secret" "prometheus-operator-grafana" {
  count      = var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]
  metadata {
    name      = "prometheus-operator-grafana"
    namespace = "monitoring"
  }
}

resource "time_sleep" "wait_60_sec" {
  count           = var.deployment_config.grafana_enabled ? 1 : 0
  depends_on      = [kubernetes_config_map.grafana_home_dashboard]
  create_duration = "60s"
}

resource "null_resource" "grafana_homepage" {
  count      = var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [time_sleep.wait_60_sec]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    curl -H 'Content-Type: application/json' -X PUT "https://${nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-user"])}:${nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-password"])}@${var.deployment_config.hostname}/api/org/preferences" -d'{ "theme": "",  "homeDashboardUId": "grafana_home_dashboard",  "timezone":"utc"}'
    EOT
  }
}
