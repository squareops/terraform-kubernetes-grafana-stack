# gcp

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
| <a name="module_gcp"></a> [gcp](#module\_gcp) | https://github.com/sq-ia/terraform-kubernetes-grafana.git//modules/resources/gcp | n/a |
| <a name="module_pgl"></a> [pgl](#module\_pgl) | git@github.com:sq-ia/terraform-kubernetes-grafana.git | n/a |

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
| <a name="output_grafana_credentials"></a> [grafana\_credentials](#output\_grafana\_credentials) | Grafana\_Info |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
