// bicep/modules/vm/vm.bicepparam
// Default parameter values — overridden per team via tfvars/pipeline params

using './vm.bicep'

param teamName            = 'changeme'
param environment         = 'prod'
param vmIndex             = '01'
param vmSku               = 'Standard_D4s_v5'
param osType              = 'Linux'
param tier                = 'medium'
param costCenter          = 'CC-0000'
param ownerEmail          = 'lead@company.com'
param patchGroup          = 'PG2'
param autoShutdown        = false
param diskEncryptionSetId = '/subscriptions/SUB_ID/resourceGroups/rg-central-services/providers/Microsoft.Compute/diskEncryptionSets/des-medium-prod'
param teamKeyVaultName    = 'kv-changeme-prod'
param subnetId            = '/subscriptions/SUB_ID/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-tier2-medium/subnets/snet-tier2-prod'
param dataDisks           = []
