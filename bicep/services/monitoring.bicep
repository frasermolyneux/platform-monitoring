targetScope = 'resourceGroup'

// Parameters

param parDeploymentPrefix string

param parAppInsightsName string

@secure()
param parAlertEmail string
@secure()
param parAlertPhone string
@secure()
param parXtremeIdiotsTaskKey string

param parLocation string

param parTags object

// Existing In-Scope Resources
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: parAppInsightsName
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

module xtremeidiotsComWebTest './../modules/webTest.bicep' = {
  name: '${parDeploymentPrefix}-xtremeidiotsComWebTest'

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

module xtremeidiotsComTaskWebTest './../modules/webTest.bicep' = {
  name: '${parDeploymentPrefix}-xtremeidiotsComTaskWebTest'

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

module redirectXtremeIdiotsNetWebTest './../modules/webTest.bicep' = {
  name: '${parDeploymentPrefix}-redirectXtremeIdiotsNetWebTest'

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

module sourcebansXtremeIdiotsNetWebTest './../modules/webTest.bicep' = {
  name: '${parDeploymentPrefix}-sourcebansXtremeIdiotsNetWebTest'

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

module tcadminXtremeIdiotsComWebTest './../modules/webTest.bicep' = {
  name: '${parDeploymentPrefix}-tcadminXtremeIdiotsComWebTest'

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

module bishopsBeesCoUkWebTest './../modules/webTest.bicep' = {
  name: '${parDeploymentPrefix}-bishopsBeesCoUkWebTest'

  params: {
    parLocation: parLocation

    parAppInsightsName: appInsights.name
    parWorkloadName: 'bishopsBees'
    parWorkloadUrl: 'https://bishopsbees.co.uk'

    parActionGroupName: criticalActionGroup.name
    parSeverity: 1

    parTags: parTags
  }
}

module molyneuxMeWebTest './../modules/webTest.bicep' = {
  name: '${parDeploymentPrefix}-molyneuxMeWebTest'

  params: {
    parLocation: parLocation

    parAppInsightsName: appInsights.name
    parWorkloadName: 'molyneuxMe'
    parWorkloadUrl: 'https://molyneux.me'

    parActionGroupName: warningActionGroup.name
    parSeverity: 1

    parTags: parTags
  }
}
