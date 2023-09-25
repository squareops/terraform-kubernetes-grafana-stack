variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "resource_group_location" {
  description = "Azure resource group location"
  type        = string
}

variable "aks_resource_group_name" {
  description = "Azure AKS resource group location"
  type        = string
}

variable "aks_cluster_name" {
  description = "Azure AKS cluster name"
  type        = string
}

variable "environment" {
  description = "Environment in which the infrastructure is being deployed (e.g., production, staging, development)"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Name of the user assigned identity"
  type        = string
  default     = "dev"
}
