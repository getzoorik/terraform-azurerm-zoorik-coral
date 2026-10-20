<p align="center">
  <img alt="Zoorik. Reduce cloud cost, autonomously." src=".github/brand/zoorik-reveal-tagline-banner-on-navy-960x240.gif" width="100%">
</p>

# terraform-azurerm-zoorik-coral

The Azure permissions the Coral agent needs on one AKS cluster. It creates the same identity, credential, role and assignment that `zoorikctl connect` creates, with the same names and tag, so zoorikctl sees them as already done.

## What it creates

- The user-assigned managed identity `zoorik-agent-<cluster>`, in the cluster's resource group and location, tagged `zoorik-cluster=<cluster id>`.
- The federated credential `zoorik-agent` on that identity. It uses the cluster's OIDC issuer, the subject `system:serviceaccount:zoorik-agent:zoorik-agent` and the audience `api://AzureADTokenExchange`.
- The custom role `Zoorik Node Removal v2`, defined at the subscription. It can read the cluster, its agent pools and their machines, delete named machines, and read its own permissions. It also has `agentPools/write`, which the agent uses to lower a pool's minimum count. With `lower_minimums = false`, the role is `Zoorik Node Removal v1` and has no `agentPools/write`.
- One assignment of that role to the identity, scoped to this cluster only.

## Before you apply

- Turn on the cluster's OIDC issuer and workload identity (`oidc_issuer_enabled` and `workload_identity_enabled`).
- Point the azurerm provider at the cluster's subscription.
- Custom role names are unique across a tenant, so only one module call creates the role. Every other cluster passes that call's `role_definition_id` output. If those clusters are in other subscriptions, list those subscriptions in the creating call's `role_assignable_scopes`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `cluster_id` | string | | The AKS cluster's resource id. |
| `location` | string | | The AKS cluster's location. |
| `oidc_issuer_url` | string | | The AKS cluster's OIDC issuer URL. |
| `lower_minimums` | bool | `true` | Lets the agent lower an agent pool's minimum count. |
| `role_definition_id` | string | `null` | The GUID of an existing `Zoorik Node Removal` role to use instead of creating one. |
| `role_assignable_scopes` | list(string) | `[]` | Where the created role may be assigned. Empty means this subscription only. |

## Outputs

| Name | Description |
|---|---|
| `client_id` | The client id of the agent's identity. |
| `role_definition_id` | The GUID of the role, for the tenant's other clusters. |

## Helm values for the coral-agent chart

```yaml
clusterResourceId: <cluster_id>
serviceAccount:
  annotations:
    azure.workload.identity/client-id: <client_id>
```

The namespace and the service account are both fixed at `zoorik-agent`, because the federated credential is bound to them.

## Your own node pool code

The agent lowers an autoscaled pool's `min_count` and records the old value in the pool tags `coral.zoorik.com_original-min` and `coral.zoorik.com_lowered-min`. Disconnect puts the minimum back. If Terraform manages those pools, ignore these changes, or each apply undoes them:

```hcl
lifecycle {
  ignore_changes = [
    min_count,
    tags["coral.zoorik.com_original-min"],
    tags["coral.zoorik.com_lowered-min"],
  ]
}
```

On the cluster's default pool, the same fields sit under `default_node_pool[0]`.

---

<p align="center"><sub><a href="https://zoorik.com">zoorik.com</a> · <a href="https://zoorik.com/docs">Docs</a> · <a href="https://zoorik.com/security">Security</a> · <a href="https://github.com/getzoorik">Zoorik on GitHub</a></sub></p>
<p align="center"><sub>The Zoorik, Coral and Amoeba names and logos belong to Zoorik Private Limited.</sub></p>
