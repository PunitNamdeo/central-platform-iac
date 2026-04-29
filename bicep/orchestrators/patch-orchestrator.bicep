// bicep/orchestrators/patch-orchestrator.bicep
// PURPOSE: Deploy/update patch maintenance configurations for all patch groups

targetScope = 'resourceGroup'

param environment string
param location    string = resourceGroup().location

module mcPG1 '../modules/patch/maintenance-config.bicep' = {
  name: 'mc-PG1-${environment}'
  params: { patchGroup: 'PG1'; environment: environment; location: location }
}

module mcPG2 '../modules/patch/maintenance-config.bicep' = {
  name: 'mc-PG2-${environment}'
  params: { patchGroup: 'PG2'; environment: environment; location: location }
}

module mcPG3 '../modules/patch/maintenance-config.bicep' = {
  name: 'mc-PG3-${environment}'
  params: { patchGroup: 'PG3'; environment: environment; location: location }
}

output pg1ConfigId string = mcPG1.outputs.maintenanceConfigId
output pg2ConfigId string = mcPG2.outputs.maintenanceConfigId
output pg3ConfigId string = mcPG3.outputs.maintenanceConfigId
