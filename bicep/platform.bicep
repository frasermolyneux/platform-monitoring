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

// Monitors
module xtremeidiotsComWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-xtremeidiotsComWebTest'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    parLocation: parLocation
    parAppInsightsName: appInsights.outputs.outAppInsightsName
    parWorkloadName: 'xtremeidiotsForums'
    parWorkloadUrl: 'https://www.xtremeidiots.com'
    parTags: parTags
  }
}

module redirectXtremeIdiotsNetWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-redirectXtremeIdiotsNetWebTest'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    parLocation: parLocation
    parAppInsightsName: appInsights.outputs.outAppInsightsName
    parWorkloadName: 'xtremeidiotsRedirect'
    parWorkloadUrl: 'https://redirect.xtremeidiots.net'
    parTags: parTags
  }
}

module sourcebansXtremeIdiotsNetWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-sourcebansXtremeIdiotsNetWebTest'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    parLocation: parLocation
    parAppInsightsName: appInsights.outputs.outAppInsightsName
    parWorkloadName: 'xtremeidiotsSourceBans'
    parWorkloadUrl: 'https://sourcebans.xtremeidiots.net'
    parTags: parTags
  }
}

module tcadminXtremeIdiotsComWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-tcadminXtremeIdiotsComWebTest'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    parLocation: parLocation
    parAppInsightsName: appInsights.outputs.outAppInsightsName
    parWorkloadName: 'xtremeidiotsTcAdmin'
    parWorkloadUrl: 'https://tcadmin.xtremeidiots.com'
    parTags: parTags
  }
}
