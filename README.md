## Prometheus Grafana Loki

![squareops_avatar]

[squareops_avatar]: https://squareops.com/wp-content/uploads/2022/12/squareops-logo.png

### [SquareOps Technologies](https://squareops.com/) Your DevOps Partner for Accelerating cloud journey.
<br>

This PGL module is for monitoring and analyzing logs and metrics from various sources. It includes these features Grafana, Prometheus, Loki, Mimir and Loki-scalable.

Grafana is an open-source platform for monitoring and observability, offering customizable dashboards, alerts, and data visualization for a wide range of data sources.

Prometheus is an open-source systems monitoring and alerting toolkit designed for reliability and scalability, providing powerful queries, storage, and visualization of time series data.

Loki is a log aggregation system that allows you to store, search, and analyze large volumes of logs from different sources. With Loki, you can quickly find the relevant logs and troubleshoot issues in your system. It uses a unique indexing method that stores metadata separately from the log data, making it very efficient and scalable.

Mimir is a metric aggregation system that allows you to collect, store, and analyze metrics from various sources. It supports various data sources such as Prometheus, Graphite, and InfluxDB. With Mimir, you can visualize metrics using a variety of charts, graphs, and dashboards.

This PGL module includes multiple dashboards that provide a comprehensive view of your system's health and performance. These dashboards include system performance, error tracking, network performance, and more.

Loki-scalable is a horizontally scalable, highly available distributed logging system designed for storing and querying logs from all your applications and infrastructure.

This module also includes alerting features that allow you to set up custom alerts for specific events or conditions. You can configure alerts to notify you via email, Slack, or other channels, and set up automated responses to resolve issues quickly.

## Supported Versions Table:

| Resources                       |  Helm Chart Version                |     K8s supported version        |  
| :-----:                         | :---                               |         :---                     |
| Kube-Prometheus-Stack           | **61.1.0**                         |    **1.23,1.24,1.25,1.26,1.27,1.28,1.29**  |
| Prometheus-Blackbox-Exporter    | **8.17.0**                         |    **1.23,1.24,1.25,1.26,1.27,1.28,1.29**  |
| Mimir                           | **5.4.0**                          |    **1.23,1.24,1.25,1.26,1.27,1.28,1.29**  |
| Loki-Stack                      | **2.10.2**                          |    **1.23,1.24,1.25,1.26,1.27,1.28,1.29**  |
| Loki-Scalable                   | **6.7.1**                          |    **1.23,1.24,1.25,1.26,1.27,1.28,1.29**  |
| Tempo                           | **1.6.2**                          |    **1.23,1.24,1.25,1.26,1.27**  |
| OTEL                            | **0.37.0**                         |    **1.23,1.24,1.25,1.26,1.27**  |


## Usage Example

```hcl
module "pgl" {
  source                        = "https://github.com/sq-ia/terraform-kubernetes-grafana.git"
  cluster_name                  = "cluster-name"
  kube_prometheus_stack_enabled = true
  loki_enabled                  = true
  loki_scalable_enabled         = false
  grafana_mimir_enabled         = true
  cloudwatch_enabled            = true
  tempo_enabled                 = false
  deployment_config = {
    hostname                            = "grafana.squareops.in"
    storage_class_name                  = "gp2"
    prometheus_values_yaml              = ""
    loki_values_yaml                    = ""
    blackbox_values_yaml                = ""
    grafana_mimir_values_yaml           = ""
    dashboard_refresh_interval          = "300"
    grafana_enabled                     = true
    prometheus_hostname                 = "prometh.squareops.in"
    prometheus_internal_ingress_enabled = false
    grafana_ingress_load_balancer       = "nlb" ##Choose your load balancer type (e.g., NLB or ALB). If using ALB, ensure you provide the ACM certificate ARN for SSL.
    alb_acm_certificate_arn             = "arn:aws:acm:us-west-2:123456543:certificate/5165ad5d-1240"
    loki_internal_ingress_enabled       = false
    loki_hostname                       = "loki.squareops.in"
    ingress_enabled                     = true
    mimir_s3_bucket_config = {
      s3_bucket_name     = ""
      versioning_enabled = "true"
      s3_bucket_region   = ""
      s3_object_expiration = 90
    }
    loki_scalable_config = {
      loki_scalable_version = "6.6.5"
      loki_scalable_values  = file("./helm/loki-scalable.yaml")
      s3_bucket_name        = ""
      versioning_enabled    = true
      s3_bucket_region      = "local.region"
    }
    promtail_config = {
      promtail_version = "6.16.3"
      promtail_values  = file("./helm/promtail.yaml")
    }
    tempo_config = {
      s3_bucket_name     = ""
      versioning_enabled = false
      s3_bucket_region   = ""
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
```
Refer [examples](https://github.com/sq-ia/terraform-kubernetes-grafana/tree/main/examples/complete) for more details.

## IAM Permissions
The required IAM permissions to create resources from this module can be found [here](https://github.com/sq-ia/terraform-kubernetes-grafana/blob/main/IAM.md)

## Important Notes
  1. In order to enable the exporter, it is required to deploy Prometheus/Grafana first.
  2. The exporter is a tool that extracts metrics data from an application or system and makes it available to be scraped by Prometheus.
  3. Prometheus is a monitoring system that collects metrics data from various sources, including exporters, and stores it in a time-series database.
  4. Grafana is a data visualization and dashboard tool that works with Prometheus and other data sources to display the collected metrics in a user-friendly way.
  5. To deploy Prometheus/Grafana, please follow the installation instructions for each tool in their respective documentation.
  6. Once Prometheus and Grafana are deployed, the exporter can be configured to scrape metrics data from your application or system and send it to Prometheus.
  7. Finally, you can use Grafana to create custom dashboards and visualize the metrics data collected by Prometheus.
  8. If we enable internal ingress for prometheus and loki then we will be able to access it on private endpoint via vpn.
  9. This module is compatible with EKS version 1.23,1.24,1.25,1.26,1.27,1.28,1.29 which is great news for users deploying the module on an EKS cluster running that version. Review the module's documentation, meet specific configuration requirements, and test thoroughly after deployment to ensure everything works as expected.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_loki_scalable_s3_bucket"></a> [loki\_scalable\_s3\_bucket](#module\_loki\_scalable\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | 4.1.2 |
| <a name="module_s3_bucket_mimir"></a> [s3\_bucket\_mimir](#module\_s3\_bucket\_mimir) | terraform-aws-modules/s3-bucket/aws | 4.1.2 |
| <a name="module_s3_bucket_temp"></a> [s3\_bucket\_temp](#module\_s3\_bucket\_temp) | terraform-aws-modules/s3-bucket/aws | 4.1.2 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.cloudwatch_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.loki_scalable_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.mimir_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.s3_tempo_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [helm_release.blackbox_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.conntrak_stats_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.consul_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.couchdb_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.druid_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.ethtool_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.grafana_mimir](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.json_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.loki](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.loki_scalable](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.nats_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.open-telemetry](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.otel-collector](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.pingdom_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus-to-sd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus_grafana](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.promtail](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.pushgateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.snmp_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.stackdriver_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.statsd_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.tempo](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map.argocd_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_acm](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_alb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_cloudfront](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_cw_logs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_dynamodb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_ebs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_efs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_inspector](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_lambda](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_nat](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_nlb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_rabbitmq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_rds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_s3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_sns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.aws_sqs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.blackbox_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.cluster_overview_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.elasticache_redis](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.elasticsearch_cluster_stats_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.elasticsearch_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.elasticsearch_exporter_quickstart_and_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.grafana_home_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.ingress_nginx_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.istio_control_plane_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.istio_performance_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.jenkins_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.kafka_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.loki_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mimir-compactor_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mimir-object-store_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mimir-overview_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mimir-queries_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mimir-reads-resources_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mimir-reads_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mimir-writes-resources_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mimir-writes_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mongodb_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.mysql_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.nifi_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.nodegroup_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.postgres_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.rabbitmq_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.redis_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_namespace.monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_priority_class.priority_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/priority_class) | resource |
| [null_resource.grafana_homepage](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.grafana_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [time_sleep.wait_180_sec](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [kubernetes_secret.prometheus-operator-grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_blackbox_exporter_version"></a> [blackbox\_exporter\_version](#input\_blackbox\_exporter\_version) | Version of the Blackbox exporter to deploy. | `string` | `"8.17.0"` | no |
| <a name="input_cloudwatch_enabled"></a> [cloudwatch\_enabled](#input\_cloudwatch\_enabled) | Whether or not to add CloudWatch as datasource and add some default dashboards for AWS in Grafana. | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Specifies the name of the EKS cluster. | `string` | n/a | yes |
| <a name="input_deployment_config"></a> [deployment\_config](#input\_deployment\_config) | Configuration options for the Prometheus, Alertmanager, Loki, and Grafana deployments, including the hostname, storage class name, dashboard refresh interval, and S3 bucket configuration for Mimir. | `any` | <pre>{<br>  "alb_acm_certificate_arn": "",<br>  "blackbox_values_yaml": "",<br>  "dashboard_refresh_interval": "",<br>  "grafana_enabled": true,<br>  "grafana_ingress_load_balancer": "nlb",<br>  "grafana_mimir_values_yaml": "",<br>  "hostname": "",<br>  "loki_hostname": "",<br>  "loki_internal_ingress_enabled": false,<br>  "loki_scalable_config": {<br>    "loki_scalable_values": "",<br>    "loki_scalable_version": "6.6.5",<br>    "s3_bucket_name": "",<br>    "s3_bucket_region": "",<br>    "versioning_enabled": ""<br>  },<br>  "loki_values_yaml": "",<br>  "mimir_s3_bucket_config": {<br>    "s3_bucket_name": "",<br>    "s3_bucket_region": "",<br>    "s3_object_expiration": "",<br>    "versioning_enabled": ""<br>  },<br>  "otel_config": {<br>    "otel_collector_enabled": false,<br>    "otel_operator_enabled": false<br>  },<br>  "prometheus_hostname": "",<br>  "prometheus_internal_ingress_enabled": false,<br>  "prometheus_values_yaml": "",<br>  "promtail_config": {<br>    "promtail_values": "",<br>    "promtail_version": "6.16.3"<br>  },<br>  "storage_class_name": "gp2",<br>  "tempo_config": {<br>    "s3_bucket_name": "",<br>    "s3_bucket_region": "",<br>    "s3_object_expiration": "",<br>    "versioning_enabled": false<br>  },<br>  "tempo_values_yaml": ""<br>}</pre> | no |
| <a name="input_exporter_config"></a> [exporter\_config](#input\_exporter\_config) | allows enabling/disabling various exporters for scraping metrics, including Consul, MongoDB, Redis, and StatsD. | `map(any)` | <pre>{<br>  "argocd": false,<br>  "blackbox": true,<br>  "conntrack": false,<br>  "consul": false,<br>  "couchdb": false,<br>  "druid": false,<br>  "elasticsearch": true,<br>  "ethtool_exporter": true,<br>  "istio": false,<br>  "jenkins": false,<br>  "json": false,<br>  "kafka": false,<br>  "mongodb": true,<br>  "mysql": true,<br>  "nats": false,<br>  "nifi": false,<br>  "pingdom": false,<br>  "postgres": false,<br>  "prometheustosd": false,<br>  "push_gateway": false,<br>  "rabbitmq": false,<br>  "redis": true,<br>  "snmp": false,<br>  "stackdriver": false,<br>  "statsd": true<br>}</pre> | no |
| <a name="input_grafana_mimir_enabled"></a> [grafana\_mimir\_enabled](#input\_grafana\_mimir\_enabled) | Specify whether or not to deploy the Grafana Mimir plugin. | `bool` | `false` | no |
| <a name="input_grafana_mimir_version"></a> [grafana\_mimir\_version](#input\_grafana\_mimir\_version) | Version of the Grafana Mimir plugin to deploy. | `string` | `"5.4.0"` | no |
| <a name="input_kube_prometheus_stack_enabled"></a> [kube\_prometheus\_stack\_enabled](#input\_kube\_prometheus\_stack\_enabled) | Specify whether or not to deploy Grafana as part of the Prometheus and Alertmanager stack. | `bool` | `false` | no |
| <a name="input_loki_enabled"></a> [loki\_enabled](#input\_loki\_enabled) | Whether or not to deploy Loki for log aggregation and querying. | `bool` | `false` | no |
| <a name="input_loki_scalable_enabled"></a> [loki\_scalable\_enabled](#input\_loki\_scalable\_enabled) | Specify whether or not to deploy the loki scalable | `bool` | `false` | no |
| <a name="input_loki_stack_version"></a> [loki\_stack\_version](#input\_loki\_stack\_version) | Version of the Loki stack to deploy. | `string` | `"2.10.2"` | no |
| <a name="input_pgl_namespace"></a> [pgl\_namespace](#input\_pgl\_namespace) | Name of the Kubernetes namespace where the Grafana deployment will be deployed. | `string` | `"monitoring"` | no |
| <a name="input_prometheus_chart_version"></a> [prometheus\_chart\_version](#input\_prometheus\_chart\_version) | Version of the Prometheus chart to deploy. | `string` | `"61.1.0"` | no |
| <a name="input_tempo_enabled"></a> [tempo\_enabled](#input\_tempo\_enabled) | Enable Grafana Tempo | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_grafana"></a> [grafana](#output\_grafana) | Grafana\_Info |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contribution & Issue Reporting

To report an issue with a project:

  1. Check the repository's [issue tracker](https://github.com/sq-ia/terraform-kubernetes-grafana/issues) on GitHub
  2. Search to see if the issue has already been reported
  3. If you can't find an answer to your question in the documentation or issue tracker, you can ask a question by creating a new issue. Be sure to provide enough context and details so others can understand your problem.

## License

Apache License, Version 2.0, January 2004 (http://www.apache.org/licenses/).

## Support Us

To support a GitHub project by liking it, you can follow these steps:

  1. Visit the repository: Navigate to the [GitHub repository](https://github.com/sq-ia/terraform-kubernetes-grafana).

  2. Click the "Star" button: On the repository page, you'll see a "Star" button in the upper right corner. Clicking on it will star the repository, indicating your support for the project.

  3. Optionally, you can also leave a comment on the repository or open an issue to give feedback or suggest changes.

Starring a repository on GitHub is a simple way to show your support and appreciation for the project. It also helps to increase the visibility of the project and make it more discoverable to others.

## Who we are

We believe that the key to success in the digital age is the ability to deliver value quickly and reliably. That’s why we offer a comprehensive range of DevOps & Cloud services designed to help your organization optimize its systems & Processes for speed and agility.

  1. We are an AWS Advanced consulting partner which reflects our deep expertise in AWS Cloud and helping 100+ clients over the last 5 years.
  2. Expertise in Kubernetes and overall container solution helps companies expedite their journey by 10X.
  3. Infrastructure Automation is a key component to the success of our Clients and our Expertise helps deliver the same in the shortest time.
  4. DevSecOps as a service to implement security within the overall DevOps process and helping companies deploy securely and at speed.
  5. Platform engineering which supports scalable,Cost efficient infrastructure that supports rapid development, testing, and deployment.
  6. 24*7 SRE service to help you Monitor the state of your infrastructure and eradicate any issue within the SLA.

We provide [support](https://squareops.com/contact-us/) on all of our projects, no matter how small or large they may be.

To find more information about our company, visit [squareops.com](https://squareops.com/), follow us on [Linkedin](https://www.linkedin.com/company/squareops-technologies-pvt-ltd/), or fill out a [job application](https://squareops.com/careers/). If you have any questions or would like assistance with your cloud strategy and implementation, please don't hesitate to [contact us](https://squareops.com/contact-us/).
