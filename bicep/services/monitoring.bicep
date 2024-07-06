targetScope = 'resourceGroup'

// Parameters

param deploymentPrefix string

@description('The app insights resource name')
param appInsightsName string

@secure()
param alertEmail string
@secure()
param alertPhone string
@secure()
param xtremeIdiotsTaskKey string

@description('The location to deploy the resources')
param location string

param tags object

// Existing In-Scope Resources
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
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
        emailAddress: alertEmail
        useCommonAlertSchema: false
      }
    ]

    smsReceivers: [
      {
        name: 'EmailAndText_-SMSAction-'
        countryCode: '44'
        phoneNumber: alertPhone
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
        emailAddress: alertEmail
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
  name: '${deploymentPrefix}-xtremeidiotsComWebTest'

  params: {
    location: location

    appInsightsName: appInsights.name
    workloadName: 'xtremeidiotsForums'
    workloadUrl: 'https://www.xtremeidiots.com'

    actionGroupName: criticalActionGroup.name
    severity: 0

    tags: tags
  }
}

module xtremeidiotsComTaskWebTest './../modules/webTest.bicep' = {
  name: '${deploymentPrefix}-xtremeidiotsComTaskWebTest'

  params: {
    location: location

    appInsightsName: appInsights.name
    workloadName: 'xtremeidiotsForumsTask'
    workloadUrl: 'https://www.xtremeidiots.com/applications/core/interface/task/web.php?key=${xtremeIdiotsTaskKey}'

    actionGroupName: criticalActionGroup.name
    severity: 1

    tags: tags
  }
}

module redirectXtremeIdiotsNetWebTest './../modules/webTest.bicep' = {
  name: '${deploymentPrefix}-redirectXtremeIdiotsNetWebTest'

  params: {
    location: location

    appInsightsName: appInsights.name
    workloadName: 'xtremeidiotsRedirect'
    workloadUrl: 'https://redirect.xtremeidiots.net'

    actionGroupName: criticalActionGroup.name
    severity: 1

    tags: tags
  }
}

module sourcebansXtremeIdiotsNetWebTest './../modules/webTest.bicep' = {
  name: '${deploymentPrefix}-sourcebansXtremeIdiotsNetWebTest'

  params: {
    location: location

    appInsightsName: appInsights.name
    workloadName: 'xtremeidiotsSourceBans'
    workloadUrl: 'https://sourcebans.xtremeidiots.net'

    actionGroupName: warningActionGroup.name
    severity: 2

    tags: tags
  }
}

module tcadminXtremeIdiotsComWebTest './../modules/webTest.bicep' = {
  name: '${deploymentPrefix}-tcadminXtremeIdiotsComWebTest'

  params: {
    location: location

    appInsightsName: appInsights.name
    workloadName: 'xtremeidiotsTcAdmin'
    workloadUrl: 'https://tcadmin.xtremeidiots.com'

    actionGroupName: criticalActionGroup.name
    severity: 1

    tags: tags
  }
}

module bishopsBeesCoUkWebTest './../modules/webTest.bicep' = {
  name: '${deploymentPrefix}-bishopsBeesCoUkWebTest'

  params: {
    location: location

    appInsightsName: appInsights.name
    workloadName: 'bishopsBees'
    workloadUrl: 'https://bishopsbees.co.uk'

    actionGroupName: criticalActionGroup.name
    severity: 1

    tags: tags
  }
}

module molyneuxMeWebTest './../modules/webTest.bicep' = {
  name: '${deploymentPrefix}-molyneuxMeWebTest'

  params: {
    location: location

    appInsightsName: appInsights.name
    workloadName: 'molyneuxMe'
    workloadUrl: 'https://molyneux.me'

    actionGroupName: warningActionGroup.name
    severity: 1

    tags: tags
  }
}
