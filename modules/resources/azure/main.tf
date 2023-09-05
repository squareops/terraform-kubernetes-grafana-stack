data "azurerm_subscription" "primary" {}

data "azurerm_kubernetes_cluster" "primary" {
  name                = var.aks_cluster_name
  resource_group_name = var.aks_resource_group_name
}

resource "azurerm_user_assigned_identity" "oidc_identity" {
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  name                = format("%s-%s-%s", var.name, var.environment, "oidc-workload-identity")
}

resource "azurerm_federated_identity_credential" "example" {
  name                = format("%s-%s-%s", var.name, var.environment, "workload-identity-credentials")
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.primary.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.oidc_identity.id
  subject             = "system:serviceaccount:default:workload-identity"
}

output "azure_service_account" {
  value       = azurerm_user_assigned_identity.oidc_identity.client_id
  description = "Azure user assigned identity for authenticating azure services"
}
