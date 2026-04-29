// bicep/modules/monitoring/log-analytics.bicep
// PURPOSE: Central Log Analytics Workspace — single for all 400 VMs

targetScope = 'resourceGroup'

param workspaceName string
param location      string = resourceGroup().location
param retentionDays int    = 90
param tags          object = {}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name:     workspaceName
  location: location
  tags:     tags
  properties: {
    retentionInDays: retentionDays
    sku: { name: 'PerGB2018' }
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output workspaceId           string = logAnalytics.id
output workspaceName         string = logAnalytics.name
output workspaceCustomerId   string = logAnalytics.properties.customerId
