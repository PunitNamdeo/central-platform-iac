// bicep/modules/keyvault/keyvault-diagnostics.bicep
// PURPOSE: Route all KV audit logs to central Log Analytics

targetScope = 'resourceGroup'

param keyVaultName            string
param logAnalyticsWorkspaceId string
param retentionDays           int = 365

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name:  'diag-${keyVaultName}'
  scope: kv
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'AuditEvent'; enabled: true; retentionPolicy: { enabled: true; days: retentionDays } }
    ]
    metrics: [
      { category: 'AllMetrics'; enabled: true; retentionPolicy: { enabled: true; days: 90 } }
    ]
  }
}
