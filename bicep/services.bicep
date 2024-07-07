targetScope = 'resourceGroup'

// Parameters
@description('The environment for the resources')
param environment string

@description('The location to deploy the resources')
param location string = resourceGroup().location

param instance string

param tags object

// Variables
var environmentUniqueId = uniqueString('monitoring', environment, instance)
var deploymentPrefix = 'services-${environmentUniqueId}' //Prevent deployment naming conflicts

var varAppInsightsName = 'ai-platform-monitoring-${environment}-${location}-${instance}'

// Existing In-Scope Resources
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-${environmentUniqueId}-${location}'
}

module monitoring 'services/monitoring.bicep' = {
  name: '${deploymentPrefix}-monitoring'

  params: {
    deploymentPrefix: deploymentPrefix

    appInsightsName: varAppInsightsName

    alertEmail: keyVault.getSecret('alert-email')
    alertPhone: keyVault.getSecret('alert-phone')
    xtremeIdiotsTaskKey: keyVault.getSecret('xtremeidiots-task-key')

    location: location
    tags: tags
  }
}
