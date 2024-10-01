locals {
  oidc_provider = replace(
    data.aws_eks_cluster.kubernetes_cluster.identity[0].oidc[0].issuer,
    "/^https:///",
    ""
  )
    base_annotations = {
    "grafana_folder" = "Defaults"
  }

  # Conditionally add CloudWatch annotation
  additional_annotations = var.cloudwatch_enabled ? {
    "eks.amazonaws.com/role-arn" = aws_iam_role.cloudwatch_role[0].arn
  } : {}

  # Merge the base annotations with the additional annotations
  annotations = merge(local.base_annotations, local.additional_annotations)

  loki_datasource_config = <<EOF

- name: Loki
  access: proxy
  type: loki
  url: http://loki-read-headless:3100
  jsonData:
    derivedFields:
      - datasourceName: Tempo
        matcherRegex: "traceID=00-([^\\-]+)-"
        name: traceID
        url: "$${__value.raw}"
        datasourceUid: tempo
  EOF

  cw_datasource_config = <<EOF

- name: CloudWatch
  type: cloudwatch
  jsonData:
    authType: default
    defaultRegion: us-east-2
  EOF

  tempo_datasource_config = <<EOF
- name: Tempo
  access: proxy
  type: tempo
  uid: tempo
  url: http://tempo-query-frontend:3100
  jsonData:
    httpMethod: GET
    serviceMap:
      datasourceUid: 'prometheus'
  version: 1
  EOF

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

#---------------------loki----------------------------------

resource "helm_release" "loki" {
  count           = var.loki_enabled ? 1 : 0
  depends_on      = [kubernetes_namespace.monitoring]
  name            = "loki"
  atomic          = true
  chart           = "loki-stack"
  version         = var.loki_stack_version
  namespace       = var.pgl_namespace
  repository      = "https://grafana.github.io/helm-charts"
  cleanup_on_fail = true
  values = [
    templatefile("${path.module}/helm/values/loki/values.yaml", {
      loki_hostname                = var.deployment_config.loki_hostname,
      enable_loki_internal_ingress = var.deployment_config.loki_internal_ingress_enabled
      storage_class_name           = var.deployment_config.storage_class_name
    }),
    var.deployment_config.loki_values_yaml
  ]
}

#---------------------blackbox----------------------------------

resource "helm_release" "blackbox_exporter" {
  count      = var.exporter_config.blackbox ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]
  name       = "blackbox-exporter"
  chart      = "prometheus-blackbox-exporter"
  version    = var.blackbox_exporter_version
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"

  values = [
    file("${path.module}/helm/values/blackbox_exporter/values.yaml"),
    var.deployment_config.blackbox_values_yaml
  ]
}

locals {
  ingress_annotations = var.deployment_config.grafana_ingress_load_balancer == "alb" ? {
    "kubernetes.io/ingress.class"                    = "alb",
    "alb.ingress.kubernetes.io/scheme"               = "internet-facing",
    "alb.ingress.kubernetes.io/group.name"           = "pgl",
    "alb.ingress.kubernetes.io/healthcheck-path"     = "/api/health",
    "alb.ingress.kubernetes.io/healthcheck-port"     = "traffic-port",
    "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP",
    "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80},{\"HTTPS\": 443}]",
    "alb.ingress.kubernetes.io/target-type"          = "ip",
    "alb.ingress.kubernetes.io/ssl-redirect"         = "443",
    "alb.ingress.kubernetes.io/certificate-arn"      = var.deployment_config.alb_acm_certificate_arn
    } : {
    "kubernetes.io/ingress.class"    = "nginx",
    "kubernetes.io/tls-acme"         = "false",
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }

  ingress_hosts = [var.deployment_config.hostname]

  ingress_tls = var.deployment_config.grafana_ingress_load_balancer == "alb" ? [] : [{
    secretName = "monitor-tls",
    hosts      = [var.deployment_config.hostname]
  }]
}

#---------------------prometheus_grafana----------------------------------

resource "helm_release" "prometheus_grafana" {
  depends_on        = [kubernetes_namespace.monitoring, kubernetes_priority_class.priority_class]
  name              = "prometheus-operator"
  chart             = "kube-prometheus-stack"
  version           = var.prometheus_chart_version
  timeout           = 600
  namespace         = var.pgl_namespace
  repository        = "https://prometheus-community.github.io/helm-charts"
  dependency_update = true

  values = var.grafana_mimir_enabled ? [
    templatefile("${path.module}/helm/values/prometheus/mimir/values.yaml", {
      hostname                = var.deployment_config.hostname,
      grafana_enabled         = var.deployment_config.grafana_enabled,
      storage_class_name      = var.deployment_config.storage_class_name,
      min_refresh_interval    = var.deployment_config.dashboard_refresh_interval,
      grafana_admin_password  = random_password.grafana_password.result,
      loki_datasource_config  = var.loki_scalable_enabled ? local.loki_datasource_config : "",
      tempo_datasource_config = var.tempo_enabled ? local.tempo_datasource_config : "",
      cw_datasource_config    = var.cloudwatch_enabled ? local.cw_datasource_config : "",
      annotations             = jsonencode(local.annotations) # Correct usage of jsonencode
    }),
    var.deployment_config.prometheus_values_yaml
    ] : [
    templatefile("${path.module}/helm/values/prometheus/values.yaml", {
      hostname                           = var.deployment_config.hostname,
      grafana_enabled                    = var.deployment_config.grafana_enabled,
      storage_class_name                 = var.deployment_config.storage_class_name,
      prometheus_hostname                = var.deployment_config.prometheus_hostname,
      min_refresh_interval               = var.deployment_config.dashboard_refresh_interval,
      grafana_admin_password             = random_password.grafana_password.result,
      enable_prometheus_internal_ingress = var.deployment_config.prometheus_internal_ingress_enabled,
      ingress_enabled                    = true,
      ingress_annotations                = jsonencode(local.ingress_annotations),
      ingress_hosts                      = jsonencode(local.ingress_hosts),
      ingress_tls                        = jsonencode(local.ingress_tls),
      loki_datasource_config             = var.loki_scalable_enabled ? local.loki_datasource_config : "",
      tempo_datasource_config            = var.tempo_enabled ? local.tempo_datasource_config : "",
      cw_datasource_config               = var.cloudwatch_enabled ? local.cw_datasource_config : "",
      annotations                        = jsonencode(local.annotations) # Correct usage of jsonencode
    }),
    var.deployment_config.prometheus_values_yaml
  ]
}

resource "helm_release" "conntrak_stats_exporter" {
  count      = var.exporter_config.conntrack ? 1 : 0
  name       = "conntrack-stats-exporter"
  chart      = "prometheus-conntrack-stats-exporter"
  version    = "0.1.0"
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  timeout    = 600
  values = [
    file("${path.module}/helm/values/conntrack.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "consul_exporter" {
  count      = var.exporter_config.consul ? 1 : 0
  name       = "consul-exporter"
  chart      = "prometheus-consul-exporter"
  version    = "0.5.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/consul.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "couchdb_exporter" {
  count      = var.exporter_config.couchdb ? 1 : 0
  name       = "couchdb-exporter"
  chart      = "prometheus-couchdb-exporter"
  version    = "0.2.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/couchdb.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "druid_exporter" {
  count      = var.exporter_config.druid ? 1 : 0
  name       = "druid-exporter"
  chart      = "prometheus-druid-exporter"
  version    = "0.11.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/druid.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "json_exporter" {
  count      = var.exporter_config.json ? 1 : 0
  name       = "json-exporter"
  chart      = "prometheus-json-exporter"
  version    = "0.13.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/json-exporter.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "nats_exporter" {
  count      = var.exporter_config.nats ? 1 : 0
  name       = "nats-exporter"
  chart      = "prometheus-nats-exporter"
  version    = "2.17.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/nats.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "pingdom_exporter" {
  count      = var.exporter_config.pingdom ? 1 : 0
  name       = "pingdom-exporter"
  chart      = "prometheus-pingdom-exporter"
  version    = "2.5.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/pingdom.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "pushgateway" {
  count      = var.exporter_config.push_gateway ? 1 : 0
  name       = "pushgateway"
  chart      = "prometheus-pushgateway"
  version    = "1.18.2"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/pushgateway.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "snmp_exporter" {
  count      = var.exporter_config.snmp ? 1 : 0
  name       = "snmp-exporter"
  chart      = "prometheus-snmp-exporter"
  version    = "1.1.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/snmp.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "stackdriver_exporter" {
  count      = var.exporter_config.stackdriver ? 1 : 0
  name       = "stackdriver-exporter"
  chart      = "prometheus-stackdriver-exporter"
  version    = "4.0.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/stackdriver.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "statsd_exporter" {
  count      = var.exporter_config.statsd ? 1 : 0
  name       = "statsd-exporter"
  chart      = "prometheus-statsd-exporter"
  version    = "0.5.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/statsd.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}

resource "helm_release" "prometheus-to-sd" {
  count      = var.exporter_config.prometheustosd ? 1 : 0
  name       = "prometheus-to-sd"
  chart      = "prometheus-to-sd"
  version    = "0.4.0"
  timeout    = 600
  namespace  = var.pgl_namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  values = [
    file("${path.module}/helm/values/prometheus-to-sd.yaml")
  ]
  depends_on = [helm_release.prometheus_grafana]
}



resource "kubernetes_priority_class" "priority_class" {
  description = "Used for grafana critical pods that must not be moved from their current"
  metadata {
    name = "grafana-pod-critical"
  }
  value             = 1000000000
  global_default    = false
  preemption_policy = "PreemptLowerPriority"
}

resource "aws_iam_role" "cloudwatch_role" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  name  = join("-", [var.cluster_name, "cloudwatch"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:aud" = "sts.amazonaws.com",
            "${local.oidc_provider}:sub" = "system:serviceaccount:monitoring:prometheus-operator-grafana"
          }
        }
      }
    ]
  })
  inline_policy {
    name = "AllowCWReadAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "cloudwatch:Describe*",
            "cloudwatch:Get*",
            "cloudwatch:List*",
            "ec2:DescribeTags",
            "logs:DescribeLogGroups",
            "logs:Get*",
            "logs:List*",
            "logs:StartQuery",
            "logs:StopQuery",
            "logs:Describe*",
            "logs:TestMetricFilter",
            "logs:FilterLogEvents",
            "logs:StartLiveTail",
            "logs:StopLiveTail",
            "oam:ListSinks",
            "sns:Get*",
            "sns:List*"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "kubernetes_config_map" "aws_rds" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-rds"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_rds.json" = "${file("${path.module}/grafana/dashboards/aws_rds.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "elasticache_redis" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "elasticache-redis"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "elasticache_redis.json" = "${file("${path.module}/grafana/dashboards/elasticache_redis.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_lambda" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-lambda"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_lambda.json" = "${file("${path.module}/grafana/dashboards/aws_lambda.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_s3" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-s3"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_s3.json" = "${file("${path.module}/grafana/dashboards/aws_s3.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_dynamodb" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-dynamodb"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_dynamodb.json" = "${file("${path.module}/grafana/dashboards/aws_dynamodb.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_sqs" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-sqs"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_sqs.json" = "${file("${path.module}/grafana/dashboards/aws_sqs.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_cw_logs" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-cw-logs"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_cw_logs.json" = "${file("${path.module}/grafana/dashboards/aws_cw_logs.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_efs" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-efs"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_efs.json" = "${file("${path.module}/grafana/dashboards/aws_efs.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_ebs" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-ebs"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_ebs.json" = "${file("${path.module}/grafana/dashboards/aws_ebs.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_nlb" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-nlb"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_nlb.json" = "${file("${path.module}/grafana/dashboards/aws_nlb.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_alb" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-alb"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_alb.json" = "${file("${path.module}/grafana/dashboards/aws_alb.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_acm" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-acm"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_acm.json" = "${file("${path.module}/grafana/dashboards/aws_acm.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_inspector" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-inspector"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_inspector.json" = "${file("${path.module}/grafana/dashboards/aws_inspector.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_cloudfront" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-cloudfront"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_cloudfront.json" = "${file("${path.module}/grafana/dashboards/aws_cloudfront.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_nat" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-nat"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_nat.json" = "${file("${path.module}/grafana/dashboards/aws_nat.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_rabbitmq" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-rabbitmq"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_rabbitmq.json" = "${file("${path.module}/grafana/dashboards/aws_rabbitmq.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

resource "kubernetes_config_map" "aws_sns" {
  count = var.deployment_config.grafana_enabled && var.cloudwatch_enabled ? 1 : 0
  metadata {
    name      = "aws-sns"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "AWS"
    }
  }

  data = {
    "aws_sns.json" = "${file("${path.module}/grafana/dashboards/aws_sns.json")}"
  }
  depends_on = [helm_release.prometheus_grafana]
}

# resource "kubernetes_config_map" "cluster_overview_dashboard" {
#   count = var.deployment_config.grafana_enabled ? 1 : 0
#   metadata {
#     name      = "prometheus-operator-kube-p-cluster-overview"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#     annotations = {
#       "grafana_folder" : "Defaults"
#     }
#   }

#   data = {
#     "cluster-overview.json" = "${file("${path.module}/grafana/dashboards/cluster_overview.json")}"
#   }
#   depends_on = [helm_release.prometheus_grafana]
# }

resource "kubernetes_config_map" "ingress_nginx_dashboard" {
  count      = var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [helm_release.prometheus_grafana]
  metadata {
    name      = "prometheus-operator-kube-p-ingress-nginx"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Nginx"
    }
  }

  data = {
    "ingress-nginx.json" = "${file("${path.module}/grafana/dashboards/ingress_nginx.json")}",
    "nginx_api_host.json" = "${file("${path.module}/grafana/dashboards/nginx_api_host.json")}",
    "nginx_ingress.json" = "${file("${path.module}/grafana/dashboards/nginx_ingress.json")}",
    "nginx_request_handling.json" = "${file("${path.module}/grafana/dashboards/nginx_request_handling.json")}"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Defaults"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Defaults"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "DataSources"
    }
  }

  data = {
    "mongodb-dashboard.json" = "${file("${path.module}/grafana/dashboards/mongodb.json")}"
  }
}

resource "kubernetes_config_map" "elasticsearch_dashboard" {
  count = var.exporter_config.elasticsearch && var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "elasticsearch-exporter"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Management"
    }
  }

  data = {
    "es-exporter.json" = "${file("${path.module}/grafana/dashboards/es-exporter.json")}"
  }
}

resource "kubernetes_config_map" "elasticsearch_cluster_stats_dashboard" {
  count = var.exporter_config.elasticsearch && var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "elasticsearch-cluster-stats"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Management"
    }
  }

  data = {
    "es-cluster-stats.json" = "${file("${path.module}/grafana/dashboards/es-cluster-stats.json")}"
  }
}


resource "kubernetes_config_map" "elasticsearch_exporter_quickstart_and_dashboard" {
  count = var.exporter_config.elasticsearch && var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "elasticsearch-exporter-quickstart-and-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Management"
    }
  }

  data = {
    "es-exporter-quickstart.json" = "${file("${path.module}/grafana/dashboards/elasticsearch-exporter-quickstart-and-dashboard.json")}"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "DataSources"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "DataSources"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "DataSources"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "DataSources"
    }
  }

  data = {
    "rabbitmq-dashboard.json" = "${file("${path.module}/grafana/dashboards/rabbitmq.json")}"
  }
}

resource "kubernetes_config_map" "loki_dashboard" {
  count = (var.loki_enabled || var.loki_scalable_enabled) && var.deployment_config.grafana_enabled ? 1 : 0
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Logs"
    }
  }

  data = {
    "loki-dashboard.json" = "${file("${path.module}/grafana/dashboards/loki.json")}",
    "analytics-nginx-logs.json" = "${file("${path.module}/grafana/dashboards/analytics_nginx_logs.json")}"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "kubernetes"
    }
  }

  data = {
    "nodegroup-dashboard.json" = "${file("${path.module}/grafana/dashboards/nodegroup.json")}",
    "cluster-dashboard.json"   = "${file("${path.module}/grafana/dashboards/k8s_view_global.json")}",
    "namespace-dashboard.json" = "${file("${path.module}/grafana/dashboards/k8s_view_namespace.json")}",
    "node-dashboard.json"      = "${file("${path.module}/grafana/dashboards/k8s_view_nodes.json")}",
    "pods-dashboard.json"      = "${file("${path.module}/grafana/dashboards/k8s_view_pods.json")}"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Management"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Management"
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
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Defaults"
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

resource "time_sleep" "wait_180_sec" {
  count           = var.deployment_config.grafana_enabled ? 1 : 0
  depends_on      = [kubernetes_config_map.grafana_home_dashboard]
  create_duration = "180s"
}

resource "null_resource" "grafana_homepage" {
  count      = var.deployment_config.grafana_enabled ? 1 : 0
  depends_on = [time_sleep.wait_180_sec]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    curl -H 'Content-Type: application/json' -X PUT "https://${nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-user"])}:${nonsensitive(data.kubernetes_secret.prometheus-operator-grafana[0].data["admin-password"])}@${var.deployment_config.hostname}/api/org/preferences" -d'{ "theme": "",  "homeDashboardUId": "grafana_home_dashboard",  "timezone":"utc"}'
    EOT
  }
}

resource "kubernetes_config_map" "istio_control_plane_dashboard" {
  depends_on = [helm_release.prometheus_grafana]
  count      = var.exporter_config.istio && var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "istio-control-plane-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Istio"
    }
  }

  data = {
    "istio-control-plane-dashboard.json" = "${file("${path.module}/grafana/dashboards/Istio_Control_Plane_Dashboard.json")}"
  }
}

# resource "kubernetes_config_map" "istio_mesh_dashboard" {
#   depends_on = [helm_release.prometheus_grafana]
#   count      = var.exporter_config.istio && var.deployment_config.grafana_enabled ? 1 : 0
#   metadata {
#     name      = "istio-mesh-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#   }

#   data = {
#     "istio-mesh-dashboard.json" = "${file("${path.module}/grafana/dashboards/Istio_Mesh_Dashboard.json")}"
#   }
# }


resource "kubernetes_config_map" "istio_performance_dashboard" {
  depends_on = [helm_release.prometheus_grafana]
  count      = var.exporter_config.istio && var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "istio-performance-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "Istio"
    }
  }

  data = {
    "istio-performance-dashboard.json" = "${file("${path.module}/grafana/dashboards/Istio_Performance_Dashboard.json")}"
  }
}


# resource "kubernetes_config_map" "istio_service_dashboard" {
#   depends_on = [helm_release.prometheus_grafana]
#   count      = var.exporter_config.istio && var.deployment_config.grafana_enabled ? 1 : 0
#   metadata {
#     name      = "istio-service-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#   }

#   data = {
#     "istio-service-dashboard.json" = "${file("${path.module}/grafana/dashboards/Istio_Service_Dashboard.json")}"
#   }
# }


# resource "kubernetes_config_map" "istio_workload_dashboard" {
#   depends_on = [helm_release.prometheus_grafana]
#   count      = var.exporter_config.istio && var.deployment_config.grafana_enabled ? 1 : 0
#   metadata {
#     name      = "istio-workload-dashboard"
#     namespace = var.pgl_namespace
#     labels = {
#       "grafana_dashboard" : "1"
#       "app" : "kube-prometheus-stack-grafana"
#       "chart" : "kube-prometheus-stack-61.1.0"
#       "release" : "prometheus-operator"
#     }
#   }

#   data = {
#     "istio-workload-dashboard.json" = "${file("${path.module}/grafana/dashboards/Istio_Workload_Dashboard.json")}"
#   }
# }


resource "kubernetes_config_map" "kafka_dashboard" {
  depends_on = [helm_release.prometheus_grafana]
  count      = var.exporter_config.kafka && var.deployment_config.grafana_enabled ? 1 : 0
  metadata {
    name      = "kafka-dashboard"
    namespace = var.pgl_namespace
    labels = {
      "grafana_dashboard" : "1"
      "app" : "kube-prometheus-stack-grafana"
      "chart" : "kube-prometheus-stack-61.1.0"
      "release" : "prometheus-operator"
    }
    annotations = {
      "grafana_folder" : "DataSources"
    }
  }

  data = {
    "kafka-dashboard.json" = "${file("${path.module}/grafana/dashboards/Kafka_Dashboard.json")}"
  }
}

resource "helm_release" "ethtool_exporter" {
  count      = var.exporter_config.ethtool_exporter ? 1 : 0
  name       = "ethtool-exporter"
  chart      = "${path.module}/helm/values/ethtool/"
  timeout    = 600
  namespace  = var.pgl_namespace
  depends_on = [helm_release.prometheus_grafana]
}
