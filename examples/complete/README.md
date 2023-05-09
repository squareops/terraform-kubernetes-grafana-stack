## Grafana Stack Example
![squareops_avatar]

[squareops_avatar]: https://squareops.com/wp-content/uploads/2022/12/squareops-logo.png

### [SquareOps Technologies](https://squareops.com/) Your DevOps Partner for Accelerating cloud journey.
<br>
This example will be very useful for users who are new to a module and want to quickly learn how to use it. By reviewing the examples, users can gain a better understanding of how the module works, what features it supports, and how to customize it to their specific needs.

## Supported Versions Table:

| Resources                       |  Helm Chart Version                |     K8s supported version   |      
| :-----:                         | :---                               |         :---                | 
| Kube-Prometheus-Stack           | **42.0.0**                         |    1.23,1.24,1.25           |
| Prometheus-Blackbox-Exporter    | **42.0.0**                         |    1.23,1.24,1.25           |
| Mimir                           | **3.2.0**                          |    1.23,1.24,1.25           |
| Loki-Stack                      | **2.8.2**                          |    1.23,1.24,1.25           |

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
| <a name="module_pgl"></a> [pgl](#module\_pgl) | ../.. | n/a |

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
| <a name="output_grafana_credentials"></a> [grafana\_credentials](#output\_grafana\_credentials) | grafana\_Info |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
