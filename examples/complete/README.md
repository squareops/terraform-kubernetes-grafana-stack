## Grafana Stack Example

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://squareops.com/wp-content/uploads/2020/05/Squareops-png-white.png1-3.png">
  <source media="(prefers-color-scheme: light)" srcset="https://squareops.com/wp-content/uploads/2021/09/Squareops-png-1-1.png">
  <img src="https://squareops.com/wp-content/uploads/2021/09/Squareops-png-1-1.png">
</picture>

### [SquareOps Technologies](https://squareops.com/) Your DevOps Partner for Accelerating cloud journey.
<br>
This example will be very useful for users who are new to a module and want to quickly learn how to use it. By reviewing the examples, users can gain a better understanding of how the module works, what features it supports, and how to customize it to their specific needs.
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
| <a name="module_pgl"></a> [pgl](#module\_pgl) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_grafana_credentials"></a> [grafana\_credentials](#output\_grafana\_credentials) | Information about the grafana including username , password & URL. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
