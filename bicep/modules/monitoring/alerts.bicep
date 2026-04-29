// bicep/modules/monitoring/alerts.bicep
// PURPOSE: Standard alert rules per VM — CPU, memory, heartbeat, patch compliance

targetScope = 'resourceGroup'

param teamName               string
param environment            string
param ownerEmail             string
param logAnalyticsWorkspaceId string
param location               string = resourceGroup().location

var vmName = 'vm-${teamName}-${environment}-eastus-01'

// Action group — email team lead on alert
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name:     'ag-${teamName}-${environment}'
  location: 'Global'
  properties: {
    groupShortName: teamName
    enabled:        true
    emailReceivers: [{
      name:                 'TeamLead'
      emailAddress:         ownerEmail
      useCommonAlertSchema: true
    }]
  }
}

// VM Heartbeat lost alert
resource heartbeatAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name:     'alert-heartbeat-${teamName}'
  location: location
  properties: {
    severity:         0
    enabled:          true
    evaluationFrequency: 'PT5M'
    windowSize:          'PT10M'
    scopes:              [ logAnalyticsWorkspaceId ]
    criteria: {
      allOf: [{
        query:           'Heartbeat | where Computer contains "${vmName}" | summarize LastHB = max(TimeGenerated) | where LastHB < ago(5m)'
        timeAggregation: 'Count'
        operator:        'GreaterThan'
        threshold:       0
        failingPeriods:  { numberOfEvaluationPeriods: 1; minFailingPeriodsToAlert: 1 }
      }]
    }
    actions: { actionGroups: [ actionGroup.id ] }
    displayName:  'VM Heartbeat Lost — ${teamName}'
    description:  'VM ${vmName} is not responding. Immediate action required.'
  }
}

output actionGroupId string = actionGroup.id
