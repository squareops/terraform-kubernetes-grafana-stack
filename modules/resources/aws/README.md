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
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3_bucket_mimir"></a> [s3\_bucket\_mimir](#module\_s3\_bucket\_mimir) | terraform-aws-modules/s3-bucket/aws | 3.7.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.mimir_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Specifies the name of the EKS cluster. | `string` | `""` | no |
| <a name="input_s3_versioning"></a> [s3\_versioning](#input\_s3\_versioning) | n/a | `bool` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | n/a |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | n/a |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_loki_scalable_s3_bucket"></a> [loki\_scalable\_s3\_bucket](#module\_loki\_scalable\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | 3.7.0 |
| <a name="module_s3_bucket_mimir"></a> [s3\_bucket\_mimir](#module\_s3\_bucket\_mimir) | terraform-aws-modules/s3-bucket/aws | 3.7.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.loki_scalable_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.mimir_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Specifies the name of the EKS cluster. | `string` | `""` | no |
| <a name="input_loki_scalable_config"></a> [loki\_scalable\_config](#input\_loki\_scalable\_config) | n/a | `any` | <pre>{<br>  "loki_scalable_values": "",<br>  "loki_scalable_version": "5.8.8",<br>  "s3_bucket_name": "",<br>  "s3_bucket_region": "",<br>  "versioning_enabled": ""<br>}</pre> | no |
| <a name="input_loki_scalable_enabled"></a> [loki\_scalable\_enabled](#input\_loki\_scalable\_enabled) | Specify whether or not to deploy the loki scalable | `bool` | `false` | no |
| <a name="input_s3_versioning"></a> [s3\_versioning](#input\_s3\_versioning) | n/a | `bool` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_loki_scalable_role"></a> [loki\_scalable\_role](#output\_loki\_scalable\_role) | IAM role for loki scalable bucket |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | IAM role arn of the loki scalable role |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | The AWS S3 bucket name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
