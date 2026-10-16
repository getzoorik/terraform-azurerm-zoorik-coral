locals {
  cluster_id_parts   = split("/", var.cluster_id)
  subscription_scope = "/subscriptions/${local.cluster_id_parts[2]}"
  resource_group     = local.cluster_id_parts[4]
  cluster_name       = local.cluster_id_parts[8]
  cluster_tag        = length(var.cluster_id) <= 256 ? var.cluster_id : "sha256:${sha256(lower(var.cluster_id))}"

  agent_subject = "system:serviceaccount:zoorik-agent:zoorik-agent"

  node_removal_actions = [
    "Microsoft.ContainerService/managedClusters/read",
    "Microsoft.ContainerService/managedClusters/agentPools/read",
    "Microsoft.ContainerService/managedClusters/agentPools/machines/read",
    "Microsoft.ContainerService/managedClusters/agentPools/deleteMachines/action",
    "Microsoft.Authorization/permissions/read",
    "Microsoft.ContainerService/managedClusters/agentPools/write",
  ]

  role_name = var.lower_minimums ? "Zoorik Node Removal v2" : "Zoorik Node Removal v1"
  role_description = var.lower_minimums ? join("", [
    "Lets the zoorik-agent of one AKS cluster read its agent pools, delete specific machines it has already ",
    "drained, and lower an agent pool's minimum count. agentPools/write is the narrowest action for that and also ",
    "allows creating or changing agent pools; the agent never creates a pool or a machine and never raises a count, ",
    "minimum or maximum.",
    ]) : join("", [
    "Lets the zoorik-agent of one AKS cluster read its agent pools and delete specific machines it has already ",
    "drained. Grants no create or scale-up.",
  ])

  role_definition_id = var.role_definition_id != null ? var.role_definition_id : one(azurerm_role_definition.node_removal[*].role_definition_id)
}

resource "azurerm_user_assigned_identity" "agent" {
  name                = "zoorik-agent-${local.cluster_name}"
  resource_group_name = local.resource_group
  location            = var.location
  tags = {
    zoorik-cluster = local.cluster_tag
  }
}

resource "azurerm_federated_identity_credential" "agent" {
  name                      = "zoorik-agent"
  user_assigned_identity_id = azurerm_user_assigned_identity.agent.id
  issuer                    = var.oidc_issuer_url
  subject                   = local.agent_subject
  audience                  = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_definition" "node_removal" {
  count             = var.role_definition_id == null ? 1 : 0
  name              = local.role_name
  scope             = local.subscription_scope
  description       = local.role_description
  assignable_scopes = coalescelist(var.role_assignable_scopes, [local.subscription_scope])

  permissions {
    actions = slice(local.node_removal_actions, 0, var.lower_minimums ? 6 : 5)
  }
}

resource "azurerm_role_assignment" "node_removal" {
  scope                            = var.cluster_id
  role_definition_id               = "${local.subscription_scope}/providers/Microsoft.Authorization/roleDefinitions/${local.role_definition_id}"
  principal_id                     = azurerm_user_assigned_identity.agent.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
