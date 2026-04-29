// bicep/modules/network/nsg.bicep
// PURPOSE: NSG with least-privilege rules per tier

targetScope = 'resourceGroup'

param nsgName       string
param location      string = resourceGroup().location
param tier          string
param bastionSubnet string = '10.0.1.0/27'
param sharedSvcSubnet string = '10.0.4.0/24'
param tags          object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name:     nsgName
  location: location
  tags:     tags
  properties: {
    securityRules: [
      {
        name: 'Allow-Bastion-SSH-RDP'
        properties: {
          priority:                 100
          direction:               'Inbound'
          access:                  'Allow'
          protocol:                'Tcp'
          sourceAddressPrefix:     bastionSubnet
          sourcePortRange:         '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges:   [ '22', '3389' ]
        }
      }
      {
        name: 'Allow-Hub-Monitoring'
        properties: {
          priority:                 110
          direction:               'Inbound'
          access:                  'Allow'
          protocol:                'Tcp'
          sourceAddressPrefix:     sharedSvcSubnet
          sourcePortRange:         '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges:   [ '443', '1270' ]
        }
      }
      {
        name: 'Deny-All-Public-Inbound'
        properties: {
          priority:                 4096
          direction:               'Inbound'
          access:                  'Deny'
          protocol:                '*'
          sourceAddressPrefix:     'Internet'
          sourcePortRange:         '*'
          destinationAddressPrefix: '*'
          destinationPortRange:    '*'
        }
      }
      {
        name: 'Allow-HTTPS-Egress'
        properties: {
          priority:                 100
          direction:               'Outbound'
          access:                  'Allow'
          protocol:                'Tcp'
          sourceAddressPrefix:     'VirtualNetwork'
          sourcePortRange:         '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange:    '443'
        }
      }
    ]
  }
}

output nsgId   string = nsg.id
output nsgName string = nsg.name
