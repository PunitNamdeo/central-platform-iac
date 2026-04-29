// bicep/modules/network/vnet.bicep
// PURPOSE: Hub or Spoke VNet creation

targetScope = 'resourceGroup'

param vnetName     string
param location     string = resourceGroup().location
param addressSpace string
param tags         object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name:     vnetName
  location: location
  tags:     tags
  properties: {
    addressSpace: {
      addressPrefixes: [ addressSpace ]
    }
  }
}

output vnetId   string = vnet.id
output vnetName string = vnet.name
