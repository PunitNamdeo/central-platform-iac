// bicep/modules/keyvault/keyvault-private-endpoint.bicep
// PURPOSE: Private endpoint for any Key Vault — no public access

targetScope = 'resourceGroup'

param keyVaultName   string
param keyVaultId     string
param subnetId       string
param location       string = resourceGroup().location

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name:     'pep-${keyVaultName}'
  location: location
  properties: {
    subnet: { id: subnetId }
    privateLinkServiceConnections: [{
      name: 'kv-plink'
      properties: {
        privateLinkServiceId: keyVaultId
        groupIds: [ 'vault' ]
      }
    }]
  }
}

output privateEndpointId string = privateEndpoint.id
