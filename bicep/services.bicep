targetScope = 'resourceGroup'

// Parameters
param parLocation string
param parEnvironment string

param parAlertEmail string
param parAlertPhone string
param parXtremeIdiotsTaskKey string

param parTags object

// Variables
var varDeploymentPrefix = 'servicesMonitoring' //Prevent deployment naming conflicts
var varAppInsightsName = 'ai-monitoring-${parEnvironment}-${parLocation}'

// Existing In-Scope Resources
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: varAppInsightsName
}

// Module Resources
resource criticalActionGroup 'microsoft.insights/actionGroups@2022-06-01' = {
  name: 'Critical'
  location: 'Global'

  properties: {
    groupShortName: 'Critical'
    enabled: true

    emailReceivers: [
      {
        name: 'EmailAndText_-EmailAction-'
        emailAddress: parAlertEmail
        useCommonAlertSchema: false
      }
    ]

    smsReceivers: [
      {
        name: 'EmailAndText_-SMSAction-'
        countryCode: '44'
        phoneNumber: parAlertPhone
      }
    ]

    webhookReceivers: []
    eventHubReceivers: []
    itsmReceivers: []
    azureAppPushReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
    armRoleReceivers: []
  }
}

resource warningActionGroup 'microsoft.insights/actionGroups@2022-06-01' = {
  name: 'Warning'
  location: 'Global'

  properties: {
    groupShortName: 'Warning'
    enabled: true

    emailReceivers: [
      {
        name: 'EmailOnly_-EmailAction-'
        emailAddress: parAlertEmail
        useCommonAlertSchema: false
      }
    ]

    smsReceivers: []
    webhookReceivers: []
    eventHubReceivers: []
    itsmReceivers: []
    azureAppPushReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
    armRoleReceivers: []
  }
}

module xtremeidiotsComWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-xtremeidiotsComWebTest'

  params: {
    parLocation: parLocation

    parAppInsightsName: appInsights.name
    parWorkloadName: 'xtremeidiotsForums'
    parWorkloadUrl: 'https://www.xtremeidiots.com'

    parActionGroupName: criticalActionGroup.name
    parSeverity: 0

    parTags: parTags
  }
}

module xtremeidiotsComTaskWebTest 'modules/webTest.bicep' = {
  name: '${varDeploymentPrefix}-xtremeidiotsComTaskWebTest'

  params: {
    parLocation: parLocation

    parAppInsightsName: appInsights.name
    parWorkloadName: 'xtremeidiotsForumsTask'
    parWorkloadUrl: 'https://www.xtremeidiots.com/applications/core/interface/task/web.php?key=${parXtremeIdiotsTaskKey}'

    parActionGroupName: criticalActionGroup.name
    parSeverity: 1

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

    parActionGroupName: criticalActionGroup.name
    parSeverity: 1

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

    parActionGroupName: warningActionGroup.name
    parSeverity: 2

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

    parActionGroupName: criticalActionGroup.name
    parSeverity: 1

    parTags: parTags
  }
}
