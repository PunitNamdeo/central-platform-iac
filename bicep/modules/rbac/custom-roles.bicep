// bicep/modules/rbac/custom-roles.bicep
// PURPOSE: Custom Patch Operator role — trigger patches, view reports only

targetScope = 'subscription'

param subscriptionId string = subscription().subscriptionId

resource patchOperatorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid('patch-operator-role', subscriptionId)
  properties: {
    roleName:    'Patch Operator'
    description: 'Trigger Azure Update Manager patches and view compliance reports only'
    type:        'CustomRole'
    permissions: [{
      actions: [
        'Microsoft.Compute/virtualMachines/read'
        'Microsoft.Maintenance/maintenanceConfigurations/read'
        'Microsoft.Maintenance/configurationAssignments/*'
        'Microsoft.GuestConfiguration/guestConfigurationAssignments/read'
        'Microsoft.OperationalInsights/workspaces/query/action'
      ]
      notActions: [
        'Microsoft.Compute/virtualMachines/write'
        'Microsoft.Compute/virtualMachines/delete'
      ]
    }]
    assignableScopes: [ '/subscriptions/${subscriptionId}' ]
  }
}

output roleDefinitionId string = patchOperatorRole.id
