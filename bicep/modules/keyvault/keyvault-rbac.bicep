// bicep/modules/keyvault/keyvault-rbac.bicep
// PURPOSE: Assign a role to a principal on a Key Vault

targetScope = 'resourceGroup'

param keyVaultName     string
param principalId      string
param roleDefinitionId string
param principalType    string = 'ServicePrincipal'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name:  guid(kv.id, principalId, roleDefinitionId)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId:   principalId
    principalType: principalType
  }
}

output roleAssignmentId string = roleAssignment.id
