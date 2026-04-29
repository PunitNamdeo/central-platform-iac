// bicep/modules/cmk/key-rotation-policy.bicep
// PURPOSE: Update rotation policy on existing CMK key
// Used when rotation schedule needs updating without recreating the key

targetScope = 'resourceGroup'

param centralKeyVaultName string
param tier                string
param environment         string
param rotationDays        int
param notifyDaysBefore    int = 14

var keyName = 'key-cmk-${tier}-${environment}'

resource centralKv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: centralKeyVaultName
}

resource cmkKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' existing = {
  parent: centralKv
  name:   keyName
}

// Note: Rotation policy is set on key creation (cmk-key.bicep)
// This module is used when schedule needs adjustment only
output keyId   string = cmkKey.id
output keyName string = cmkKey.name
