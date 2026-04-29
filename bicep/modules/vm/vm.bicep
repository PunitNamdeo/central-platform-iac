// bicep/modules/vm/vm.bicep
// PURPOSE: Core VM module — CMK enforced, SSH key from team KV
// MANAGED BY: Central Platform Team only

targetScope = 'resourceGroup'

@description('Team name')
param teamName string

@description('Environment: prod / dev / staging')
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('VM index e.g. 01')
param vmIndex string = '01'

@description('VM SKU — driven by tier parameter')
param vmSku string

@description('OS type: Linux or Windows')
@allowed(['Linux', 'Windows'])
param osType string = 'Linux'

@description('Tier: heavy / medium / light')
@allowed(['heavy', 'medium', 'light'])
param tier string

@description('Cost center code')
param costCenter string

@description('Owner email address')
param ownerEmail string

@description('Patch group: PG1 / PG2 / PG3')
@allowed(['PG1', 'PG2', 'PG3'])
param patchGroup string

@description('Auto shutdown flag — true for Tier 3')
param autoShutdown bool = false

@description('Disk Encryption Set resource ID for CMK — REQUIRED')
param diskEncryptionSetId string

@description('Team Key Vault name to retrieve SSH public key')
param teamKeyVaultName string

@description('Subnet resource ID')
param subnetId string

@description('Additional data disks')
param dataDisks array = []

var vmName  = 'vm-${teamName}-${environment}-${location}-${vmIndex}'
var nicName = 'nic-${teamName}-${environment}-${vmIndex}'
var osDiskName = 'osdisk-${teamName}-${environment}-${vmIndex}'

var tags = {
  team:           teamName
  environment:    environment
  tier:           tier
  'cost-center':  costCenter
  'owner-email':  ownerEmail
  'patch-group':  patchGroup
  'auto-shutdown': string(autoShutdown)
  'provisioned-by': 'bicep-pipeline'
  'created-date': utcNow('yyyy-MM-dd')
}

// Reference existing team Key Vault
resource teamKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: teamKeyVaultName
}

// Network Interface Card
resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [{
      name: 'ipconfig1'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: { id: subnetId }
      }
    }]
  }
}

// Virtual Machine — CMK enforced on OS disk and all data disks
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'  // Managed identity for KV secret access at runtime
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSku
    }
    storageProfile: {
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
          diskEncryptionSet: {
            id: diskEncryptionSetId  // CMK applied
          }
        }
      }
      imageReference: osType == 'Linux' ? {
        publisher: 'Canonical'
        offer:     '0001-com-ubuntu-server-jammy'
        sku:       '22_04-lts-gen2'
        version:   'latest'
      } : {
        publisher: 'MicrosoftWindowsServer'
        offer:     'WindowsServer'
        sku:       '2022-datacenter-g2'
        version:   'latest'
      }
      dataDisks: [for (disk, i) in dataDisks: {
        lun: i
        createOption: 'Empty'
        diskSizeGB: disk.sizeGB
        managedDisk: {
          storageAccountType: 'Premium_LRS'
          diskEncryptionSet: {
            id: diskEncryptionSetId  // CMK on all data disks too
          }
        }
      }]
    }
    osProfile: {
      computerName:  vmName
      adminUsername: 'azureadmin'
      linuxConfiguration: osType == 'Linux' ? {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [{
            path:    '/home/azureadmin/.ssh/authorized_keys'
            keyData: teamKeyVault.getSecret('ssh-public-key-${teamName}')
          }]
        }
        patchSettings: {
          patchMode:           'AutomaticByPlatform'
          assessmentMode:      'AutomaticByPlatform'
        }
      } : null
      windowsConfiguration: osType == 'Windows' ? {
        enableAutomaticUpdates: false  // Managed by Azure Update Manager
        patchSettings: {
          patchMode:      'AutomaticByPlatform'
          assessmentMode: 'AutomaticByPlatform'
        }
      } : null
    }
    networkProfile: {
      networkInterfaces: [{ id: nic.id }]
    }
    diagnosticsProfile: {
      bootDiagnostics: { enabled: true }
    }
  }
}

output vmId         string = vm.id
output vmName       string = vm.name
output privateIp    string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output nicId        string = nic.id
output principalId  string = vm.identity.principalId
