targetScope = 'resourceGroup'

// Parameters
param parLocation string
param parEnvironment string

param parTags object

// Variables
var varDeploymentPrefix = 'servicesMonitoring' //Prevent deployment naming conflicts
var varAppInsightsName = 'ai-monitoring-${parEnvironment}-${parLocation}'

// Existing In-Scope Resources
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: varAppInsightsName
}

// Module Resources
module xtremeidiotsComWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-xtremeidiotsComWebTest'

  params: {
    parLocation: parLocation
    parAppInsightsName: appInsights.name
    parWorkloadName: 'xtremeidiotsForums'
    parWorkloadUrl: 'https://www.xtremeidiots.com'
    parTags: parTags
  }
}

module redirectXtremeIdiotsNetWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-redirectXtremeIdiotsNetWebTest'

  params: {
    parLocation: parLocation
    parAppInsightsName: appInsights.name
    parWorkloadName: 'xtremeidiotsRedirect'
    parWorkloadUrl: 'https://redirect.xtremeidiots.net'
    parTags: parTags
  }
}

module sourcebansXtremeIdiotsNetWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-sourcebansXtremeIdiotsNetWebTest'

  params: {
    parLocation: parLocation
    parAppInsightsName: appInsights.name
    parWorkloadName: 'xtremeidiotsSourceBans'
    parWorkloadUrl: 'https://sourcebans.xtremeidiots.net'
    parTags: parTags
  }
}

module tcadminXtremeIdiotsComWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-tcadminXtremeIdiotsComWebTest'

  params: {
    parLocation: parLocation
    parAppInsightsName: appInsights.name
    parWorkloadName: 'xtremeidiotsTcAdmin'
    parWorkloadUrl: 'https://tcadmin.xtremeidiots.com'
    parTags: parTags
  }
}
