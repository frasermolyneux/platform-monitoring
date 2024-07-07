targetScope = 'resourceGroup'

// Parameters
@description('The key vault resource name')
param keyVaultName string

@description('The location to deploy the resources')
param location string = resourceGroup().location

param tags object

@description('Must be set to "default" if the Key Vault does not exist. Setting to "recover" avoids the accessPolicies being wiped each time.')
param keyVaultCreateMode string = 'recover'

param enabledForDeployment bool = false
param enabledForTemplateDeployment bool = false

param enabledForRbacAuthorization bool = false

param softDeleteRetentionInDays int = 90

// Module Resources
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags

  properties: {
    accessPolicies: []
    createMode: keyVaultCreateMode

    enablePurgeProtection: true
    enableRbacAuthorization: enabledForRbacAuthorization
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment

    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }

    sku: {
      family: 'A'
      name: 'standard'
    }

    softDeleteRetentionInDays: softDeleteRetentionInDays

    tenantId: tenant().tenantId
  }
}

// Outputs
output outKeyVaultName string = keyVault.name
