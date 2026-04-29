// bicep/modules/rbac/role-assignment.bicep
// PURPOSE: Generic role assignment — used for any scope

targetScope = 'resourceGroup'

param principalId      string
param principalType    string = 'Group'
param roleDefinitionId string  // Built-in role GUID
param description      string = ''

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId:      principalId
    principalType:    principalType
    description:      description
  }
}

output roleAssignmentId string = roleAssignment.id
