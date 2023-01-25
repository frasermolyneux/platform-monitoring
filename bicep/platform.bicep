targetScope = 'subscription'

// Parameters
param parEnvironment string
param parLocation string
param parInstance string

param parDeployPrincipalId string

param parLoggingSubscriptionId string
param parLoggingResourceGroupName string
param parLoggingWorkspaceName string

param parPlatformKeyVaultCreateMode string = 'recover'

param parTags object

// Variables
var environmentUniqueId = uniqueString('monitoring', parEnvironment, parInstance)
var varDeploymentPrefix = 'platform-${environmentUniqueId}' //Prevent deployment naming conflicts

var varResourceGroupName = 'rg-platform-monitoring-${parEnvironment}-${parLocation}-${parInstance}'
var varKeyVaultName = 'kv-${environmentUniqueId}-${parLocation}'
var varAppInsightsName = 'ai-platform-monitoring-${parEnvironment}-${parLocation}-${parInstance}'

// Platform
resource defaultResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: varResourceGroupName
  location: parLocation
  tags: parTags

  properties: {}
}

module keyVault 'modules/keyVault.bicep' = {
  name: '${varDeploymentPrefix}-keyVault'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    parKeyVaultName: varKeyVaultName
    parLocation: parLocation

    parKeyVaultCreateMode: parPlatformKeyVaultCreateMode
    parEnabledForDeployment: true
    parEnabledForTemplateDeployment: true
    parEnabledForRbacAuthorization: true

    parSoftDeleteRetentionInDays: 30

    parTags: parTags
  }
}

@description('https://learn.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#key-vault-secrets-officer')
resource keyVaultSecretsOfficerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
}

module keyVaultSecretUserRoleAssignment 'modules/keyVaultRoleAssignment.bicep' = {
  name: '${varDeploymentPrefix}-keyVaultSecretUserRoleAssignment'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    parKeyVaultName: keyVault.outputs.outKeyVaultName
    parRoleDefinitionId: keyVaultSecretsOfficerRoleDefinition.id
    parPrincipalId: parDeployPrincipalId
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: '${varDeploymentPrefix}-appInsights'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    parAppInsightsName: varAppInsightsName
    parLocation: parLocation
    parLoggingSubscriptionId: parLoggingSubscriptionId
    parLoggingResourceGroupName: parLoggingResourceGroupName
    parLoggingWorkspaceName: parLoggingWorkspaceName
    parTags: parTags
  }
}

// Outputs
output resourceGroupName string = defaultResourceGroup.name
