targetScope = 'resourceGroup'

// Parameters
@description('The location to deploy the resources')
param location string = resourceGroup().location

@description('The app insights resource name')
param appInsightsName string
param workloadName string
param workloadUrl string

param actionGroupName string
param severity int

param tags object

// Existing In-Scope Resources
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource actionGroup 'microsoft.insights/actionGroups@2022-06-01' existing = {
  name: actionGroupName
}

// Module Resources
resource webTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: '${workloadName}-webTest'
  location: location
  tags: union(tags, {
    'hidden-link:${appInsights.id}': 'Resource'
  })

  properties: {
    SyntheticMonitorId: '${workloadName}-availability-test'
    Name: '${workloadName}-availability-test'
    Enabled: true
    Frequency: 300
    Timeout: 120
    Kind: 'ping'
    RetryEnabled: true

    Locations: [
      {
        Id: 'emea-ru-msa-edge'
      }
      {
        Id: 'emea-se-sto-edge'
      }
      {
        Id: 'us-il-ch1-azr'
      }
      {
        Id: 'emea-ch-zrh-edge'
      }
      {
        Id: 'apac-hk-hkn-azr'
      }
    ]

    Configuration: {
      WebTest: '<WebTest Name="${workloadName}-availability-test" Id="1f60b4da-4c5f-4d68-9b9b-afe669fa26e4" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="120" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale=""> <Items> <Request Method="GET" Guid="a4c43a5a-cc8c-b111-1f8a-7b7f03187fd1" Version="1.1" Url="${workloadUrl}" ThinkTime="0" Timeout="120" ParseDependentRequests="False" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" /> </Items> </WebTest>'
    }
  }
}

resource metricAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${workloadName}-metricAlert'
  location: 'global'

  tags: union(tags, {
    'hidden-link:${appInsights.id}': 'Resource'
    'hidden-link:${webTest.id}': 'Resource'
  })

  properties: {
    description: 'Alert rule for availability test "${webTest.name}"'
    severity: severity
    enabled: true

    scopes: [
      webTest.id
      appInsights.id
    ]

    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'

    criteria: {
      webTestId: webTest.id
      componentId: appInsights.id
      failedLocationCount: 2
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
    }

    actions: [
      {
        actionGroupId: actionGroup.id
        webHookProperties: {}
      }
    ]
  }
}
