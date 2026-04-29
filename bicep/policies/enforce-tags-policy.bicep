// bicep/policies/enforce-tags-policy.bicep
// PURPOSE: Azure Policy — DENY resources without mandatory tags
// Mandatory tags: team, environment, tier, cost-center, owner-email, patch-group

targetScope = 'managementGroup'

resource taggingPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'deny-resources-without-mandatory-tags'
  properties: {
    displayName: 'Deny resources without mandatory tags'
    policyType:  'Custom'
    mode:        'Indexed'
    parameters:  {}
    policyRule: {
      if: {
        anyOf: [
          { field: 'tags[team]';         exists: false }
          { field: 'tags[environment]';  exists: false }
          { field: 'tags[tier]';         exists: false }
          { field: 'tags[cost-center]';  exists: false }
          { field: 'tags[owner-email]';  exists: false }
          { field: 'tags[patch-group]';  exists: false }
        ]
      }
      then: { effect: 'Deny' }
    }
  }
}

output policyId string = taggingPolicy.id
