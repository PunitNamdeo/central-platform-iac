// bicep/policies/enforce-cmk-policy.bicep
// PURPOSE: Azure Policy — DENY VM disks without CMK (DES) attached
// Applied at Management Group level — cascades to all 400 VMs

targetScope = 'managementGroup'

param managementGroupId string
param environment       string

resource cmkPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'deny-vm-without-cmk'
  properties: {
    displayName: 'Deny VM disks without Customer Managed Key (CMK)'
    description: 'All VM OS disks and data disks must use a Disk Encryption Set with CMK. Enforced by Central Platform Team.'
    policyType:  'Custom'
    mode:        'Indexed'
    parameters:  {}
    policyRule: {
      if: {
        allOf: [
          { field: 'type'; equals: 'Microsoft.Compute/virtualMachines' }
          {
            anyOf: [
              { field: 'Microsoft.Compute/virtualMachines/storageProfile.osDisk.managedDisk.diskEncryptionSet.id'; exists: false }
              { field: 'Microsoft.Compute/virtualMachines/storageProfile.osDisk.managedDisk.diskEncryptionSet.id'; equals: '' }
            ]
          }
        ]
      }
      then: {
        effect: 'Deny'  // Block creation if CMK not attached
      }
    }
  }
}

output policyId string = cmkPolicy.id
