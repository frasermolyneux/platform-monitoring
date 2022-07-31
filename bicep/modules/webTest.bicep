targetScope = 'resourceGroup'

// Parameters
param parLocation string

param parAppInsightsName string
param parWorkloadName string
param parWorkloadUrl string

param parActionGroupName string
param parSeverity int

param parTags object

// Existing In-Scope Resources
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: parAppInsightsName
}

resource actionGroup 'microsoft.insights/actionGroups@2022-06-01' existing = {
  name: parActionGroupName
}

// Module Resources
resource webTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: '${parWorkloadName}-webTest'
  location: parLocation
  tags: union(parTags, {
      'hidden-link:${appInsights.id}': 'Resource'
    })

  properties: {
    SyntheticMonitorId: '${parWorkloadName}-availability-test'
    Name: '${parWorkloadName}-availability-test'
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
      WebTest: '<WebTest Name="${parWorkloadName}-availability-test" Id="1f60b4da-4c5f-4d68-9b9b-afe669fa26e4" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="120" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale=""> <Items> <Request Method="GET" Guid="a4c43a5a-cc8c-b111-1f8a-7b7f03187fd1" Version="1.1" Url="${parWorkloadUrl}" ThinkTime="0" Timeout="120" ParseDependentRequests="False" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" /> </Items> </WebTest>'
    }
  }
}

resource metricAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${parWorkloadName}-metricAlert'
  location: 'global'

  tags: union(parTags, {
      'hidden-link:${appInsights.id}': 'Resource'
      'hidden-link:${webTest.id}': 'Resource'
    })

  properties: {
    description: 'Alert rule for availability test "${webTest.name}"'
    severity: parSeverity
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
