// bicep/orchestrators/vm-full-stack.bicep
// PURPOSE: Deploy complete VM stack for one team
// Includes: KV + VM (CMK) + RBAC + patch enrollment + monitoring alerts

targetScope = 'resourceGroup'

param teamName                 string
param environment              string
param location                 string = resourceGroup().location
param tier                     string
param vmSku                    string
param costCenter               string
param ownerEmail               string
param subnetId                 string
param diskEncryptionSetId      string   // Passed in from platform outputs (tier-based)
param centralTeamSpObjectId    string
param deployPipelineSpObjectId string
param teamLeadGroupObjectId    string
param developerGroupObjectId   string
param logAnalyticsWorkspaceId  string
param privateEndpointSubnetId  string
param maintenanceConfigId      string
param dataDisks                array = []

var patchGroupMap = { heavy: 'PG3'; medium: 'PG2'; light: 'PG1' }
var patchGroup    = patchGroupMap[tier]
var autoShutdown  = tier == 'light'

// ── 1. Team Key Vault ───────────────────────────────────
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

// ── 2. VM with CMK ──────────────────────────────────────
module vm '../modules/vm/vm.bicep' = {
  name: 'vm-${teamName}-${environment}'
  dependsOn: [ teamKv ]
  params: {
    teamName:            teamName
    environment:         environment
    location:            location
    vmSku:               vmSku
    tier:                tier
    costCenter:          costCenter
    ownerEmail:          ownerEmail
    patchGroup:          patchGroup
    autoShutdown:        autoShutdown
    diskEncryptionSetId: diskEncryptionSetId
    teamKeyVaultName:    teamKv.outputs.keyVaultName
    subnetId:            subnetId
    dataDisks:           dataDisks
  }
}

// ── 3. RBAC: Team Lead — VM Contributor ─────────────────
module rbacTeamLead '../modules/rbac/role-assignment.bicep' = {
  name: 'rbac-teamlead-${teamName}'
  params: {
    principalId:      teamLeadGroupObjectId
    principalType:    'Group'
    roleDefinitionId: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'  // Virtual Machine Contributor
    description:      'Team Lead — start/stop/restart VM in ${teamName} RG'
  }
}

// ── 4. RBAC: Developers — VM User Login ─────────────────
module rbacDev '../modules/rbac/role-assignment.bicep' = {
  name: 'rbac-dev-${teamName}'
  params: {
    principalId:      developerGroupObjectId
    principalType:    'Group'
    roleDefinitionId: 'fb879df8-f326-4884-b1cf-06f3ad86be52'  // Virtual Machine User Login
    description:      'Developers — SSH/RDP login via Bastion only'
  }
}

// ── 5. Patch enrollment ──────────────────────────────────
module patchEnroll '../modules/patch/update-manager.bicep' = {
  name: 'patch-${teamName}-${patchGroup}'
  dependsOn: [ vm ]
  params: {
    vmName:                   vm.outputs.vmName
    patchGroup:               patchGroup
    environment:              environment
    location:                 location
    maintenanceConfigurationId: maintenanceConfigId
  }
}

// ── 6. Monitoring alerts ─────────────────────────────────
module alerts '../modules/monitoring/alerts.bicep' = {
  name: 'alerts-${teamName}-${environment}'
  dependsOn: [ vm ]
  params: {
    teamName:                teamName
    environment:             environment
    ownerEmail:              ownerEmail
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    location:                location
  }
}

output vmId          string = vm.outputs.vmId
output vmName        string = vm.outputs.vmName
output privateIp     string = vm.outputs.privateIp
output keyVaultName  string = teamKv.outputs.keyVaultName
