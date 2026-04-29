// bicep/modules/cmk/disk-encryption-set.bicep
// PURPOSE: Create Disk Encryption Set (DES) — links CMK key to VM disks
// One DES per tier — shared by all VMs in that tier (confirmed design)

targetScope = 'resourceGroup'

param tier               string
param environment        string
param cmkKeyUri          string
param centralKeyVaultId  string
param location           string = resourceGroup().location

var desName = 'des-${tier}-${environment}'
var tags = {
  tier:            tier
  environment:     environment
  'provisioned-by':'bicep-pipeline'
  'cmk-managed':   'true'
}

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-04-02' = {
  name:     desName
  location: location
  tags:     tags
  identity: { type: 'SystemAssigned' }   // DES uses this MI to access KV
  properties: {
    encryptionType: 'EncryptionAtRestWithCustomerKey'
    activeKey: {
      keyUrl:      cmkKeyUri
      sourceVault: { id: centralKeyVaultId }
    }
    rotationToLatestKeyVersionEnabled: true   // Auto-uses new key version on rotation
  }
}

// Give DES managed identity access to unwrap/wrap keys in central KV
resource desKvAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(centralKeyVaultId, diskEncryptionSet.id, 'CryptoServiceEncUser')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')
    principalId:   diskEncryptionSet.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output diskEncryptionSetId                string = diskEncryptionSet.id
output diskEncryptionSetName              string = diskEncryptionSet.name
output desManagedIdentityPrincipalId      string = diskEncryptionSet.identity.principalId
