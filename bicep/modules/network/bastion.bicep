// bicep/modules/network/bastion.bicep
// PURPOSE: Azure Bastion — central secure VM access, no public IPs on VMs

targetScope = 'resourceGroup'

param bastionName  string
param location     string = resourceGroup().location
param subnetId     string
param tags         object = {}

resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name:     'pip-${bastionName}'
  location: location
  tags:     tags
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name:     bastionName
  location: location
  tags:     tags
  sku: { name: 'Standard' }
  properties: {
    scaleUnits: 2
    ipConfigurations: [{
      name: 'bastionIpConfig'
      properties: {
        subnet:          { id: subnetId }
        publicIPAddress: { id: bastionPip.id }
      }
    }]
  }
}

output bastionId   string = bastion.id
output bastionName string = bastion.name
