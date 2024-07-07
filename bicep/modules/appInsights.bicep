targetScope = 'resourceGroup'

// Parameters
@description('The app insights resource name')
param appInsightsName string

@description('The location to deploy the resources')
param location string = resourceGroup().location

param loggingSubscriptionId string
param loggingResourceGroupName string
param loggingWorkspaceName string
param tags object

// Existing Out-Of-Scope Resources
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: loggingWorkspaceName
  scope: resourceGroup(loggingSubscriptionId, loggingResourceGroupName)
}

// Module Resources
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags

  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Outputs
output outAppInsightsName string = appInsights.name
