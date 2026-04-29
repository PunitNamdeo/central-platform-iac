// bicep/modules/cmk/cmk-key.bicep
// PURPOSE: Create CMK key in central HSM Key Vault — one per tier
// Confirmed: 1 key per tier (3 keys total for 400 VMs)

targetScope = 'resourceGroup'

@description('Tier: tier1 / tier2 / tier3')
@allowed(['tier1', 'tier2', 'tier3'])
param tier string

@description('Environment')
param environment string

@description('Central HSM Key Vault name')
param centralKeyVaultName string

// Key specs per tier — different size/rotation per risk level
var keyConfig = {
  tier1: { keySize: 4096; keyType: 'RSA-HSM'; rotationDays: 90;  expiryDays: 95  }
  tier2: { keySize: 3072; keyType: 'RSA-HSM'; rotationDays: 180; expiryDays: 185 }
  tier3: { keySize: 2048; keyType: 'RSA';     rotationDays: 365; expiryDays: 370 }
}

var cfg     = keyConfig[tier]
var keyName = 'key-cmk-${tier}-${environment}'

resource centralKv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: centralKeyVaultName
}

resource cmkKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: centralKv
  name:   keyName
  properties: {
    kty:     cfg.keyType
    keySize: cfg.keySize
    keyOps:  [ 'wrapKey', 'unwrapKey' ]
    rotationPolicy: {
      attributes: {
        expiryTime: 'P${cfg.expiryDays}D'
      }
      lifetimeActions: [
        {
          trigger: { timeBeforeExpiry: 'P10D' }
          action:  { type: 'Rotate' }   // Auto-rotate 10 days before expiry
        }
        {
          trigger: { timeAfterCreate: 'P${cfg.rotationDays}D' }
          action:  { type: 'Notify' }   // Alert CT on rotation
        }
      ]
    }
    attributes: {
      enabled:    true
      exportable: false   // Key CANNOT be exported
    }
  }
}

output cmkKeyId   string = cmkKey.id
output cmkKeyUri  string = cmkKey.properties.keyUriWithVersion
output cmkKeyName string = cmkKey.name
