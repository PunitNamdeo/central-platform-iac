// bicep/modules/patch/update-manager.bicep
// PURPOSE: Enroll VM in Azure Update Manager with correct patch group

targetScope = 'resourceGroup'

param vmName         string
param patchGroup     string
param environment    string
param location       string = resourceGroup().location
param maintenanceConfigurationId string = ''

var maintenanceConfigName = 'mc-${patchGroup}-${environment}'

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: vmName
}

// Configuration assignment — links VM to maintenance schedule
resource configAssignment 'Microsoft.Maintenance/configurationAssignments@2023-04-01' = {
  name:     '${vmName}-${patchGroup}'
  location: location
  scope:    vm
  properties: {
    maintenanceConfigurationId: maintenanceConfigurationId != '' ? maintenanceConfigurationId : resourceId('Microsoft.Maintenance/maintenanceConfigurations', maintenanceConfigName)
    resourceId:                 vm.id
  }
}

output assignmentId string = configAssignment.id
