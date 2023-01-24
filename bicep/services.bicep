targetScope = 'resourceGroup'

// Parameters
param parLocation string
param parEnvironment string

param parTags object

// Variables
var varDeploymentPrefix = 'servicesMonitoring' //Prevent deployment naming conflicts
var varAppInsightsName = 'ai-platform-monitoring-${uniqueString(subscription().id)}-${parEnvironment}-${parLocation}'

// Existing In-Scope Resources
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-${uniqueString(subscription().id)}-${parLocation}'
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
