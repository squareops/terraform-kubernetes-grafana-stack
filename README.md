## Prometheus Grafana Loki

![squareops_avatar]

[squareops_avatar]: https://squareops.com/wp-content/uploads/2022/12/squareops-logo.png

### [SquareOps Technologies](https://squareops.com/) Your DevOps Partner for Accelerating cloud journey.
<br>

This PGL module is for monitoring and analyzing logs and metrics from various sources. It includes two main features, Loki and Mimir.

Loki is a log aggregation system that allows you to store, search, and analyze large volumes of logs from different sources. With Loki, you can quickly find the relevant logs and troubleshoot issues in your system. It uses a unique indexing method that stores metadata separately from the log data, making it very efficient and scalable.

Mimir is a metric aggregation system that allows you to collect, store, and analyze metrics from various sources. It supports various data sources such as Prometheus, Graphite, and InfluxDB. With Mimir, you can visualize metrics using a variety of charts, graphs, and dashboards.

This PGL module includes multiple dashboards that provide a comprehensive view of your system's health and performance. These dashboards include system performance, error tracking, network performance, and more.

This module also includes alerting features that allow you to set up custom alerts for specific events or conditions. You can configure alerts to notify you via email, Slack, or other channels, and set up automated responses to resolve issues quickly.


## Usage Example

```hcl
module "pgl" {
  source                        = "../.."
  cluster_name                  = "cluster-name"
  kube_prometheus_stack_enabled = true
  loki_enabled                  = true
  grafana_mimir_enabled         = true
  deployment_config = {
    hostname                           = "grafana.squareops.in"
    storage_class_name                 = "gp2"
    prometheus_values_yaml             = file("./helm/prometheus.yaml")
    loki_values_yaml                   = file("./helm/loki.yaml")
    blackbox_values_yaml               = file("./helm/blackbox.yaml")
    grafana_mimir_values_yaml          = file("./helm/mimir.yaml")
    dashboard_refresh_interval         = "300"
    grafana_enabled                    = true
    prometheus_hostname                = "prometh.squareops.in"
    enable_prometheus_internal_ingress = false
    enable_loki_internal_ingress       = false
    loki_hostname                      = "loki.squareops.in"
    mimir_s3_bucket_config = {
      s3_bucket_name     = "bucket-name"
      versioning_enabled = "true"
      s3_bucket_region   = "bucket-region"
    }
    karpenter_enabled = true
    karpenter_config = {
      private_subnet_name                  = "private-subnet"
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


```
Refer [examples](https://github.com/sq-ia/terraform-kubernetes-grafana-stack/tree/main/examples/complete) for more details.

## IAM Permissions
The required IAM permissions to create resources from this module can be found [here](https://github.com/sq-ia/terraform-kubernetes-grafana-stack/blob/main/IAM.md)

## Important Notes
  1. In order to enable the exporter, it is required to deploy Prometheus/Grafana first.
  2. The exporter is a tool that extracts metrics data from an application or system and makes it available to be scraped by Prometheus.
  3. Prometheus is a monitoring system that collects metrics data from various sources, including exporters, and stores it in a time-series database.
  4. Grafana is a data visualization and dashboard tool that works with Prometheus and other data sources to display the collected metrics in a user-friendly way.
  5. To deploy Prometheus/Grafana, please follow the installation instructions for each tool in their respective documentation.
  6. Once Prometheus and Grafana are deployed, the exporter can be configured to scrape metrics data from your application or system and send it to Prometheus.
  7. Finally, you can use Grafana to create custom dashboards and visualize the metrics data collected by Prometheus.
  8. If we enable internal ingress for prometheus and loki then we will be able to access it on private endpoint via vpn.
  9. This module is compatible with EKS version 1.23, which is great news for users deploying the module on an EKS cluster running that version. Review the module's documentation, meet specific configuration requirements, and test thoroughly after deployment to ensure everything works as expected.

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
| <a name="module_s3_bucket_mimir"></a> [s3\_bucket\_mimir](#module\_s3\_bucket\_mimir) | terraform-aws-modules/s3-bucket/aws | 3.7.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.mimir_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [helm_release.blackbox_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cloudwatch_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.conntrak_stats_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.consul_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.couchdb_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.druid_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.elasticsearch_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.grafana_mimir](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.json_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kafka_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter_provisioner](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.loki](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.nats_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.pingdom_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.postgres_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus-to-sd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.prometheus_grafana](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.pushgateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.snmp_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.stackdriver_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.statsd_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map.argocd_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.blackbox_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.cluster_overview_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.grafana_home_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.ingress_nginx_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.jenkins_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
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
| [kubernetes_secret.cloudwatch_cred](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.grafana_homepage](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.grafana_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [time_sleep.wait_60_sec](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [kubernetes_secret.prometheus-operator-grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_access_key_id"></a> [aws\_access\_key\_id](#input\_aws\_access\_key\_id) | provide aws access key for creating the cloudwatch secret | `string` | `""` | no |
| <a name="input_aws_cw_secret"></a> [aws\_cw\_secret](#input\_aws\_cw\_secret) | Set to true if want to create kubernetes secret for cloudwatch exporter | `bool` | `false` | no |
| <a name="input_aws_secret_key_id"></a> [aws\_secret\_key\_id](#input\_aws\_secret\_key\_id) | provide aws secret key for creating the cloudwatch secret | `string` | `""` | no |
| <a name="input_blackbox_exporter_version"></a> [blackbox\_exporter\_version](#input\_blackbox\_exporter\_version) | Enter Blackbox exporter version | `string` | `"4.10.1"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_deployment_config"></a> [deployment\_config](#input\_deployment\_config) | PGL configurations | `any` | <pre>{<br>  "blackbox_values_yaml": "",<br>  "dashboard_refresh_interval": "",<br>  "grafana_enabled": true,<br>  "grafana_mimir_values_yaml": "",<br>  "hostname": "",<br>  "karpenter_config": {<br>    "excluded_instance_type": [<br>      ""<br>    ],<br>    "instance_capacity_type": [<br>      ""<br>    ],<br>    "karpenter_values": "",<br>    "private_subnet_name": ""<br>  },<br>  "karpenter_enabled": "",<br>  "loki_hostname": "",<br>  "loki_internal_ingress_enabled": false,<br>  "loki_values_yaml": "",<br>  "mimir_s3_bucket_config": {<br>    "s3_bucket_name": "",<br>    "s3_bucket_region": "",<br>    "versioning_enabled": ""<br>  },<br>  "prometheus_hostname": "",<br>  "prometheus_internal_ingress_enabled": false,<br>  "prometheus_values_yaml": "",<br>  "storage_class_name": "gp2"<br>}</pre> | no |
| <a name="input_exporter_config"></a> [exporter\_config](#input\_exporter\_config) | n/a | `map(any)` | <pre>{<br>  "argocd": false,<br>  "blackbox": true,<br>  "cloudwatch": false,<br>  "conntrack": false,<br>  "consul": false,<br>  "couchdb": false,<br>  "druid": false,<br>  "elasticsearch": true,<br>  "jenkins": false,<br>  "json": false,<br>  "kafka": false,<br>  "mongodb": true,<br>  "mysql": true,<br>  "nats": false,<br>  "nifi": false,<br>  "pingdom": false,<br>  "postgres": false,<br>  "prometheustosd": false,<br>  "push_gateway": false,<br>  "rabbitmq": false,<br>  "redis": true,<br>  "snmp": false,<br>  "stackdriver": false,<br>  "statsd": true<br>}</pre> | no |
| <a name="input_grafana_mimir_enabled"></a> [grafana\_mimir\_enabled](#input\_grafana\_mimir\_enabled) | Set true to grafana mimir | `bool` | `false` | no |
| <a name="input_grafana_mimir_version"></a> [grafana\_mimir\_version](#input\_grafana\_mimir\_version) | Enter grafana mimir version | `string` | `"3.2.0"` | no |
| <a name="input_kube_prometheus_stack_enabled"></a> [kube\_prometheus\_stack\_enabled](#input\_kube\_prometheus\_stack\_enabled) | Set true to deploy grafana | `bool` | `false` | no |
| <a name="input_loki_enabled"></a> [loki\_enabled](#input\_loki\_enabled) | Set true to deploy loki | `bool` | `false` | no |
| <a name="input_loki_stack_version"></a> [loki\_stack\_version](#input\_loki\_stack\_version) | Enter loki stack Version | `string` | `"2.8.2"` | no |
| <a name="input_pgl_namespace"></a> [pgl\_namespace](#input\_pgl\_namespace) | n/a | `string` | `"monitoring"` | no |
| <a name="input_prometheus_chart_version"></a> [prometheus\_chart\_version](#input\_prometheus\_chart\_version) | Enter prometheus\_chart\_version | `string` | `"42.0.0"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_grafana"></a> [grafana](#output\_grafana) | Grafana\_Info |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contribution & Issue Reporting

To report an issue with a project:

  1. Check the repository's [issue tracker](https://github.com/sq-ia/terraform-kubernetes-grafana-stack/issues) on GitHub
  2. Search to see if the issue has already been reported
  3. If you can't find an answer to your question in the documentation or issue tracker, you can ask a question by creating a new issue. Be sure to provide enough context and details so others can understand your problem.

## License

Apache License, Version 2.0, January 2004 (http://www.apache.org/licenses/).

## Support Us

To support a GitHub project by liking it, you can follow these steps:

  1. Visit the repository: Navigate to the [GitHub repository](https://github.com/sq-ia/terraform-kubernetes-grafana-stack).

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
