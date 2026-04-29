// bicep/modules/keyvault/central-keyvault.bicep
// PURPOSE: Central HSM-backed Key Vault — one for entire platform
// Stores: CMK keys (per tier), pipeline SPs, backup keys
// Access: Central Team ONLY via private endpoint

targetScope = 'resourceGroup'

param environment                string
param location                   string = resourceGroup().location
param centralTeamSpObjectId      string
param deployPipelineSpObjectId   string
param logAnalyticsWorkspaceId    string
param privateEndpointSubnetId    string

var keyVaultName = 'kv-central-platform-${environment}'
var tags = {
  team:            'central-platform'
  environment:     environment
  tier:            'platform'
  'managed-by':    'central-team'
  'provisioned-by':'bicep-pipeline'
  'cmk-vault':     'true'
}

resource centralKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name:     keyVaultName
  location: location
  tags:     tags
  properties: {
    sku: { family: 'A'; name: 'premium' }  // HSM-backed
    tenantId:               subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete:        true
    softDeleteRetentionInDays: 90
    enablePurgeProtection:   true          // Immutable once set
    publicNetworkAccess:     'Disabled'    // No public access
    networkAcls: {
      defaultAction: 'Deny'
      bypass:        'AzureServices'
      ipRules:       []
      virtualNetworkRules: []
    }
  }
}

// Central Team — Key Vault Administrator
resource ctAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name:  guid(centralKeyVault.id, centralTeamSpObjectId, 'KVAdministrator')
  scope: centralKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId:  centralTeamSpObjectId
    principalType: 'ServicePrincipal'
  }
}

// Deploy Pipeline SP — Key Vault Crypto User (wrap/unwrap only)
resource pipelineCryptoUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name:  guid(centralKeyVault.id, deployPipelineSpObjectId, 'KVCryptoUser')
  scope: centralKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '12338af0-0e69-4776-bea7-57ae8d297424')
    principalId:  deployPipelineSpObjectId
    principalType: 'ServicePrincipal'
  }
}

// Private Endpoint — only access method
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name:     'pep-${keyVaultName}'
  location: location
  tags:     tags
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [{
      name: 'kv-connection'
      properties: {
        privateLinkServiceId: centralKeyVault.id
        groupIds: [ 'vault' ]
      }
    }]
  }
}

// Diagnostics — ALL access events to Log Analytics
resource kvDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name:  'diag-${keyVaultName}'
  scope: centralKeyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'AuditEvent';                    enabled: true; retentionPolicy: { enabled: true; days: 365 } }
      { category: 'AzurePolicyEvaluationDetails';  enabled: true; retentionPolicy: { enabled: true; days: 365 } }
    ]
    metrics: [
      { category: 'AllMetrics'; enabled: true; retentionPolicy: { enabled: true; days: 90 } }
    ]
  }
}

output keyVaultId   string = centralKeyVault.id
output keyVaultName string = centralKeyVault.name
output keyVaultUri  string = centralKeyVault.properties.vaultUri
