targetScope = 'subscription'

// Parameters
param parLocation string
param parEnvironment string

param parLoggingSubscriptionId string
param parLoggingResourceGroupName string
param parLoggingWorkspaceName string

param parTags object

// Variables
var varDeploymentPrefix = 'platformMonitoring' //Prevent deployment naming conflicts
var varResourceGroupName = 'rg-platform-monitoring-${parEnvironment}-${parLocation}'
var varKeyVaultName = 'kv-monitor-${parEnvironment}-${parLocation}'
var varAppInsightsName = 'ai-monitoring-${parEnvironment}-${parLocation}'

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
    parTags: parTags
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: '${varDeploymentPrefix}-appInsights'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    parAppInsightsName: varAppInsightsName
    parKeyVaultName: keyVault.outputs.outKeyVaultName
    parLocation: parLocation
    parLoggingSubscriptionId: parLoggingSubscriptionId
    parLoggingResourceGroupName: parLoggingResourceGroupName
    parLoggingWorkspaceName: parLoggingWorkspaceName
    parTags: parTags
  }
}
