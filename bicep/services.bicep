targetScope = 'resourceGroup'

// Parameters
param parEnvironment string
param parLocation string
param parInstance string

param parTags object

// Variables
var varEnvironmentUniqueId = uniqueString('monitoring', parEnvironment, parInstance)
var varDeploymentPrefix = 'services-${varEnvironmentUniqueId}' //Prevent deployment naming conflicts

var varAppInsightsName = 'ai-platform-monitoring-${parEnvironment}-${parLocation}-${parInstance}'

// Existing In-Scope Resources
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-${varEnvironmentUniqueId}-${parLocation}'
}

module monitoring 'services/monitoring.bicep' = {
  name: '${varDeploymentPrefix}-monitoring'

  params: {
    parDeploymentPrefix: varDeploymentPrefix

    parAppInsightsName: varAppInsightsName

    parAlertEmail: keyVault.getSecret('alert-email')
    parAlertPhone: keyVault.getSecret('alert-phone')
    parXtremeIdiotsTaskKey: keyVault.getSecret('xtremeidiots-task-key')

    parLocation: parLocation
    parTags: parTags
  }
}
