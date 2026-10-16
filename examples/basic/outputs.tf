output "agent_client_id" {
  description = "Service account annotation azure.workload.identity/client-id."
  value       = module.zoorik_coral.client_id
}

output "cluster_resource_id" {
  description = "The agent's clusterResourceId."
  value       = data.azurerm_kubernetes_cluster.this.id
}
