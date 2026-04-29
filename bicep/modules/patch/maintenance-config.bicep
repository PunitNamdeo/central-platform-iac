// bicep/modules/patch/maintenance-config.bicep
// PURPOSE: Define patch schedule per patch group
// PG1: Light VMs — every 2 weeks Sunday 1AM
// PG2: Medium VMs — every 2 weeks Sunday 3AM
// PG3: Heavy VMs — 1st Saturday monthly 12AM (manual approval)

targetScope = 'resourceGroup'

@allowed(['PG1', 'PG2', 'PG3'])
param patchGroup  string
param environment string
param location    string = resourceGroup().location

var schedules = {
  PG1: { startTime: '2024-01-07 01:00'; recur: 'Week';  interval: 2; day: 'Sunday';   duration: '02:00' }
  PG2: { startTime: '2024-01-07 03:00'; recur: 'Week';  interval: 2; day: 'Sunday';   duration: '03:00' }
  PG3: { startTime: '2024-01-06 00:00'; recur: 'Month'; interval: 1; day: 'Saturday'; duration: '04:00' }
}

var sched = schedules[patchGroup]
var configName = 'mc-${patchGroup}-${environment}'

resource maintenanceConfig 'Microsoft.Maintenance/maintenanceConfigurations@2023-04-01' = {
  name:     configName
  location: location
  tags: {
    'patch-group':    patchGroup
    environment:      environment
    'provisioned-by': 'bicep-pipeline'
  }
  properties: {
    maintenanceScope: 'InGuestPatch'
    installPatches: {
      rebootSetting: 'IfRequired'
      linuxParameters: {
        classificationsToInclude: patchGroup == 'PG3' ? [ 'Critical', 'Security', 'Other' ] : [ 'Critical', 'Security' ]
      }
      windowsParameters: {
        classificationsToInclude: patchGroup == 'PG3' ? [ 'Critical', 'Security', 'UpdateRollup', 'FeaturePack', 'ServicePack', 'Definition', 'Tools', 'Updates' ] : [ 'Critical', 'Security' ]
      }
    }
    window: {
      startDateTime:       sched.startTime
      duration:            sched.duration
      timeZone:            'UTC'
      recurEvery:          '${sched.interval}${sched.recur}'
    }
  }
}

output maintenanceConfigId   string = maintenanceConfig.id
output maintenanceConfigName string = maintenanceConfig.name
