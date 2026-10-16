output "client_id" {
  description = "Client id of the agent's managed identity, for the service account annotation azure.workload.identity/client-id."
  value       = azurerm_user_assigned_identity.agent.client_id
}

output "role_definition_id" {
  description = "GUID of the \"Zoorik Node Removal\" role, to pass as role_definition_id for the tenant's other clusters."
  value       = local.role_definition_id
}
