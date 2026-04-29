// bicep/orchestrators/keyvault-orchestrator.bicep
// PURPOSE: Deploy full KV stack for one team
// Called by: onboard-team.yml + deploy-vm.yml (kv-only mode)

targetScope = 'resourceGroup'

param teamName                  string
param environment               string
param location                  string = resourceGroup().location
param centralTeamSpObjectId     string
param deployPipelineSpObjectId  string
param teamLeadGroupObjectId     string
param developerGroupObjectId    string
param logAnalyticsWorkspaceId   string
param privateEndpointSubnetId   string

// ── Team Key Vault ───────────────────────────────────────
module teamKv '../modules/keyvault/team-keyvault.bicep' = {
  name: 'kv-${teamName}-${environment}'
  params: {
    teamName:                  teamName
    environment:               environment
    location:                  location
    centralTeamSpObjectId:     centralTeamSpObjectId
    deployPipelineSpObjectId:  deployPipelineSpObjectId
    teamLeadGroupObjectId:     teamLeadGroupObjectId
    developerGroupObjectId:    developerGroupObjectId
    logAnalyticsWorkspaceId:   logAnalyticsWorkspaceId
    privateEndpointSubnetId:   privateEndpointSubnetId
  }
}

// ── VM Managed Identity → KV Secrets User ───────────────
// Allows VM to read its own secrets at runtime
// Developers do NOT get direct KV access
module vmMiKvAccess '../modules/keyvault/keyvault-rbac.bicep' = {
  name: 'kv-rbac-vm-mi-${teamName}'
  dependsOn: [ teamKv ]
  params: {
    keyVaultName:      teamKv.outputs.keyVaultName
    principalId:       'REPLACE_WITH_VM_MI_PRINCIPAL_ID'  // Injected by pipeline after VM creation
    roleDefinitionId:  '4633458b-17de-408a-b874-0445c86b69e6'  // Key Vault Secrets User
    principalType:     'ServicePrincipal'
  }
}

// ── KV Diagnostics ───────────────────────────────────────
module kvDiag '../modules/keyvault/keyvault-diagnostics.bicep' = {
  name: 'kv-diag-${teamName}-${environment}'
  dependsOn: [ teamKv ]
  params: {
    keyVaultName:            teamKv.outputs.keyVaultName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    retentionDays:           365
  }
}

output keyVaultId   string = teamKv.outputs.keyVaultId
output keyVaultName string = teamKv.outputs.keyVaultName
output keyVaultUri  string = teamKv.outputs.keyVaultUri
