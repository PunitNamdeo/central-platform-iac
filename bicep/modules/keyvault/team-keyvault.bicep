// bicep/modules/keyvault/team-keyvault.bicep
// PURPOSE: Per-team Key Vault — 1 per team (400 total), fully CT-managed
// Teams: READ secrets only. CT: full admin. Devs: via VM managed identity only.

targetScope = 'resourceGroup'

param teamName                  string
param environment               string
param location                  string = resourceGroup().location
param centralTeamSpObjectId     string
param deployPipelineSpObjectId  string
param teamLeadGroupObjectId     string
param developerGroupObjectId    string
param logAnalyticsWorkspaceId   string
param privateEndpointSubnetId   string

var keyVaultName = 'kv-${teamName}-${environment}'
var tags = {
  team:            teamName
  environment:     environment
  'provisioned-by':'bicep-pipeline'
  'managed-by':    'central-team'
}

resource teamKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name:     keyVaultName
  location: location
  tags:     tags
  properties: {
    sku: { family: 'A'; name: 'standard' }
    tenantId:                subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete:        true
    softDeleteRetentionInDays: 30
    enablePurgeProtection:   true
    publicNetworkAccess:     'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass:        'AzureServices'
    }
  }
}

// Central Team: Key Vault Administrator
resource ctAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name:  guid(teamKeyVault.id, centralTeamSpObjectId, 'KVAdmin')
  scope: teamKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId:   centralTeamSpObjectId
    principalType: 'ServicePrincipal'
  }
}

// Deploy Pipeline: Secrets User (read during deployments)
resource pipelineSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name:  guid(teamKeyVault.id, deployPipelineSpObjectId, 'KVSecretsUser')
  scope: teamKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId:   deployPipelineSpObjectId
    principalType: 'ServicePrincipal'
  }
}

// Team Lead Group: Secrets User (read their own secrets — no manage)
resource teamLeadReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name:  guid(teamKeyVault.id, teamLeadGroupObjectId, 'KVSecretsUser')
  scope: teamKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId:   teamLeadGroupObjectId
    principalType: 'Group'
  }
}

// Developers: NO direct KV access — access via VM managed identity only

// Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name:     'pep-${keyVaultName}'
  location: location
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [{
      name: 'kv-link'
      properties: {
        privateLinkServiceId: teamKeyVault.id
        groupIds: [ 'vault' ]
      }
    }]
  }
}

// Diagnostics
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name:  'diag-${keyVaultName}'
  scope: teamKeyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'AuditEvent'; enabled: true; retentionPolicy: { enabled: true; days: 365 } }
    ]
  }
}

output keyVaultId   string = teamKeyVault.id
output keyVaultName string = teamKeyVault.name
output keyVaultUri  string = teamKeyVault.properties.vaultUri
