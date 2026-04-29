// bicep/orchestrators/platform-setup.bicep
// PURPOSE: ONE-TIME platform setup
// Creates: HSM Key Vault + 3 CMK keys (per tier) + 3 Disk Encryption Sets
//          + Log Analytics Workspace + Azure Bastion + Hub VNet
// Run ONCE before any team is onboarded

targetScope = 'resourceGroup'

param environment  string
param location     string = resourceGroup().location
param region       string = 'eastus'

param centralTeamSpObjectId    string
param deployPipelineSpObjectId string

param hubVnetAddressSpace      string = '10.0.0.0/16'
param bastionSubnetPrefix      string = '10.0.1.0/27'
param sharedSvcSubnetPrefix    string = '10.0.4.0/24'

var tags = {
  'managed-by':    'central-team'
  environment:     environment
  'provisioned-by':'bicep-pipeline'
}

// ── Log Analytics Workspace ──────────────────────────────
module logAnalytics '../modules/monitoring/log-analytics.bicep' = {
  name: 'deploy-law-${environment}'
  params: {
    workspaceName: 'law-central-${environment}'
    location:      location
    retentionDays: 90
    tags:          tags
  }
}

// ── Hub VNet ──────────────────────────────────────────────
module hubVnet '../modules/network/vnet.bicep' = {
  name: 'deploy-hub-vnet'
  params: {
    vnetName:     'vnet-central-hub'
    location:     location
    addressSpace: hubVnetAddressSpace
    tags:         tags
  }
}

// ── Central HSM Key Vault ────────────────────────────────
module centralKv '../modules/keyvault/central-keyvault.bicep' = {
  name: 'deploy-central-kv-${environment}'
  dependsOn: [ logAnalytics ]
  params: {
    environment:               environment
    location:                  location
    centralTeamSpObjectId:     centralTeamSpObjectId
    deployPipelineSpObjectId:  deployPipelineSpObjectId
    logAnalyticsWorkspaceId:   logAnalytics.outputs.workspaceId
    privateEndpointSubnetId:   '${hubVnet.outputs.vnetId}/subnets/snet-shared-services'
  }
}

// ── CMK Keys (1 per tier) ────────────────────────────────
module cmkKeyTier1 '../modules/cmk/cmk-key.bicep' = {
  name: 'deploy-cmk-tier1-${environment}'
  dependsOn: [ centralKv ]
  params: {
    tier:                 'tier1'
    environment:          environment
    centralKeyVaultName:  centralKv.outputs.keyVaultName
  }
}

module cmkKeyTier2 '../modules/cmk/cmk-key.bicep' = {
  name: 'deploy-cmk-tier2-${environment}'
  dependsOn: [ centralKv ]
  params: {
    tier:                 'tier2'
    environment:          environment
    centralKeyVaultName:  centralKv.outputs.keyVaultName
  }
}

module cmkKeyTier3 '../modules/cmk/cmk-key.bicep' = {
  name: 'deploy-cmk-tier3-${environment}'
  dependsOn: [ centralKv ]
  params: {
    tier:                 'tier3'
    environment:          environment
    centralKeyVaultName:  centralKv.outputs.keyVaultName
  }
}

// ── Disk Encryption Sets (1 per tier) ───────────────────
module desTier1 '../modules/cmk/disk-encryption-set.bicep' = {
  name: 'deploy-des-tier1-${environment}'
  dependsOn: [ cmkKeyTier1 ]
  params: {
    tier:               'tier1'
    environment:        environment
    cmkKeyUri:          cmkKeyTier1.outputs.cmkKeyUri
    centralKeyVaultId:  centralKv.outputs.keyVaultId
    location:           location
  }
}

module desTier2 '../modules/cmk/disk-encryption-set.bicep' = {
  name: 'deploy-des-tier2-${environment}'
  dependsOn: [ cmkKeyTier2 ]
  params: {
    tier:               'tier2'
    environment:        environment
    cmkKeyUri:          cmkKeyTier2.outputs.cmkKeyUri
    centralKeyVaultId:  centralKv.outputs.keyVaultId
    location:           location
  }
}

module desTier3 '../modules/cmk/disk-encryption-set.bicep' = {
  name: 'deploy-des-tier3-${environment}'
  dependsOn: [ cmkKeyTier3 ]
  params: {
    tier:               'tier3'
    environment:        environment
    cmkKeyUri:          cmkKeyTier3.outputs.cmkKeyUri
    centralKeyVaultId:  centralKv.outputs.keyVaultId
    location:           location
  }
}

// ── Patch Maintenance Configurations (PG1/PG2/PG3) ──────
module mcPG1 '../modules/patch/maintenance-config.bicep' = {
  name: 'deploy-mc-PG1-${environment}'
  params: { patchGroup: 'PG1'; environment: environment; location: location }
}

module mcPG2 '../modules/patch/maintenance-config.bicep' = {
  name: 'deploy-mc-PG2-${environment}'
  params: { patchGroup: 'PG2'; environment: environment; location: location }
}

module mcPG3 '../modules/patch/maintenance-config.bicep' = {
  name: 'deploy-mc-PG3-${environment}'
  params: { patchGroup: 'PG3'; environment: environment; location: location }
}

output centralKvName         string = centralKv.outputs.keyVaultName
output logAnalyticsId        string = logAnalytics.outputs.workspaceId
output desTier1Id            string = desTier1.outputs.diskEncryptionSetId
output desTier2Id            string = desTier2.outputs.diskEncryptionSetId
output desTier3Id            string = desTier3.outputs.diskEncryptionSetId
