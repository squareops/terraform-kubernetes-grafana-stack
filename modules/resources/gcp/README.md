## Grafana Stack Example
![squareops_avatar]

[squareops_avatar]: https://squareops.com/wp-content/uploads/2022/12/squareops-logo.png

### [SquareOps Technologies](https://squareops.com/) Your DevOps Partner for Accelerating cloud journey.
<br>
This example will be very useful for users who are new to a module and want to quickly learn how to use it. By reviewing the examples, users can gain a better understanding of how the module works, what features it supports, and how to customize it to their specific needs.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gcs_buckets"></a> [gcs\_buckets](#module\_gcs\_buckets) | terraform-google-modules/cloud-storage/google | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [google_project_iam_member.secretadmin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.service_account_token_creator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.grafana_mimir](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.pod_identity](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_GCP_GSA_NAME"></a> [GCP\_GSA\_NAME](#input\_GCP\_GSA\_NAME) | Google Cloud Service Account name | `string` | `"mimir"` | no |
| <a name="input_GCP_KSA_NAME"></a> [GCP\_KSA\_NAME](#input\_GCP\_KSA\_NAME) | Google Kubernetes Service Account name | `string` | `"grafana-mimir-sa"` | no |
| <a name="input_deployment_config"></a> [deployment\_config](#input\_deployment\_config) | Configuration options for the Prometheus, Alertmanager, Loki, and Grafana deployments, including the hostname, storage class name, dashboard refresh interval, and S3 bucket configuration for Mimir. | `any` | <pre>{<br>  "blackbox_values_yaml": "",<br>  "dashboard_refresh_interval": "",<br>  "grafana_enabled": true,<br>  "grafana_mimir_values_yaml": "",<br>  "hostname": "",<br>  "karpenter_config": {<br>    "excluded_instance_type": [<br>      ""<br>    ],<br>    "instance_capacity_type": [<br>      ""<br>    ],<br>    "karpenter_values": "",<br>    "private_subnet_name": ""<br>  },<br>  "karpenter_enabled": true,<br>  "loki_hostname": "",<br>  "loki_internal_ingress_enabled": false,<br>  "loki_values_yaml": "",<br>  "mimir_bucket_config": {<br>    "s3_bucket_region": "",<br>    "versioning_enabled": ""<br>  },<br>  "prometheus_hostname": "",<br>  "prometheus_internal_ingress_enabled": false,<br>  "prometheus_values_yaml": "",<br>  "storage_class_name": "gp2"<br>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment in which the infrastructure is being deployed (e.g., production, staging, development) | `string` | `"dev"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Bucket name. |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | Service Account Name |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gcs_buckets"></a> [gcs\_buckets](#module\_gcs\_buckets) | terraform-google-modules/cloud-storage/google | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [google_project_iam_member.secretadmin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.service_account_token_creator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.grafana_mimir](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.pod_identity](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_GCP_GSA_NAME"></a> [GCP\_GSA\_NAME](#input\_GCP\_GSA\_NAME) | Google Cloud Service Account name | `string` | `"mimir"` | no |
| <a name="input_GCP_KSA_NAME"></a> [GCP\_KSA\_NAME](#input\_GCP\_KSA\_NAME) | Google Kubernetes Service Account name | `string` | `"grafana-mimir-sa"` | no |
| <a name="input_deployment_config"></a> [deployment\_config](#input\_deployment\_config) | Configuration options for the Prometheus, Alertmanager, Loki, and Grafana deployments, including the hostname, storage class name, dashboard refresh interval, and S3 bucket configuration for Mimir. | `any` | <pre>{<br>  "blackbox_values_yaml": "",<br>  "dashboard_refresh_interval": "",<br>  "grafana_enabled": true,<br>  "grafana_mimir_values_yaml": "",<br>  "hostname": "",<br>  "karpenter_config": {<br>    "excluded_instance_type": [<br>      ""<br>    ],<br>    "instance_capacity_type": [<br>      ""<br>    ],<br>    "karpenter_values": "",<br>    "private_subnet_name": ""<br>  },<br>  "karpenter_enabled": true,<br>  "loki_hostname": "",<br>  "loki_internal_ingress_enabled": false,<br>  "loki_values_yaml": "",<br>  "mimir_bucket_config": {<br>    "s3_bucket_region": "",<br>    "versioning_enabled": ""<br>  },<br>  "prometheus_hostname": "",<br>  "prometheus_internal_ingress_enabled": false,<br>  "prometheus_values_yaml": "",<br>  "storage_class_name": "gp2"<br>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment in which the infrastructure is being deployed (e.g., production, staging, development) | `string` | `"dev"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Bucket name. |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | Service Account Name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
