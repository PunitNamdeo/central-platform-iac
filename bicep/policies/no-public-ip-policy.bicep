// bicep/policies/no-public-ip-policy.bicep
// PURPOSE: Azure Policy — DENY public IP creation on team VMs
// All VM access must go through Azure Bastion (centrally managed)

targetScope = 'managementGroup'

resource noPublicIpPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'deny-public-ip-on-vm-nic'
  properties: {
    displayName: 'Deny public IP addresses on VM network interfaces'
    policyType:  'Custom'
    mode:        'Indexed'
    parameters:  {}
    policyRule: {
      if: {
        allOf: [
          { field: 'type'; equals: 'Microsoft.Network/networkInterfaces' }
          {
            count: {
              field: 'Microsoft.Network/networkInterfaces/ipConfigurations[*].publicIpAddress.id'
            }
            greater: 0
          }
        ]
      }
      then: { effect: 'Deny' }
    }
  }
}

output policyId string = noPublicIpPolicy.id
