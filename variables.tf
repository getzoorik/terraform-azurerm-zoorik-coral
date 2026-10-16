variable "cluster_id" {
  description = "Resource id of the AKS cluster, /subscriptions/<subscription>/resourceGroups/<group>/providers/Microsoft.ContainerService/managedClusters/<name>."
  type        = string
}

variable "location" {
  description = "Location of the AKS cluster. The agent's managed identity is created there."
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster. The cluster needs the OIDC issuer and workload identity turned on."
  type        = string
}

variable "lower_minimums" {
  description = "Let the agent lower an agent pool's minimum count when that minimum alone keeps a node it has emptied. Off gives the role that only deletes drained machines."
  type        = bool
  default     = true
}

variable "role_definition_id" {
  description = "GUID of a \"Zoorik Node Removal\" role already defined in this tenant, for example the role_definition_id output of this module for another cluster. Role names are unique in a tenant, so only one cluster's module creates the role."
  type        = string
  default     = null
}

variable "role_assignable_scopes" {
  description = "Scopes the created role may be assigned in, such as /subscriptions/<id> for every subscription in this tenant whose clusters will use it. Empty means this cluster's subscription only."
  type        = list(string)
  default     = []
}
