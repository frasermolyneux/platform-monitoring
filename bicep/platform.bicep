targetScope = 'subscription'

// Parameters
@description('The environment for the resources')
param environment string

@description('The location to deploy the resources')
param location string
param instance string

param deployPrincipalId string

param loggingSubscriptionId string
param loggingResourceGroupName string
param loggingWorkspaceName string

param keyVaultCreateMode string = 'recover'

param tags object

// Variables
var environmentUniqueId = uniqueString('monitoring', environment, instance)
var deploymentPrefix = 'platform-${environmentUniqueId}' //Prevent deployment naming conflicts

var resourceGroupName = 'rg-platform-monitoring-${environment}-${location}-${instance}'
var keyVaultName = 'kv-${environmentUniqueId}-${location}'
var varAppInsightsName = 'ai-platform-monitoring-${environment}-${location}-${instance}'

// Platform
resource defaultResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags

  properties: {}
}

module keyVault 'modules/keyVault.bicep' = {
  name: '${deploymentPrefix}-keyVault'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    keyVaultName: keyVaultName
    location: location

    keyVaultCreateMode: keyVaultCreateMode
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForRbacAuthorization: true

    softDeleteRetentionInDays: 30

    tags: tags
  }
}

@description('https://learn.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#key-vault-secrets-officer')
resource keyVaultSecretsOfficerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
}

module keyVaultSecretUserRoleAssignment 'modules/keyVaultRoleAssignment.bicep' = {
  name: '${deploymentPrefix}-keyVaultSecretUserRoleAssignment'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    keyVaultName: keyVault.outputs.outKeyVaultName
    principalId: deployPrincipalId
    roleDefinitionId: keyVaultSecretsOfficerRoleDefinition.id
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: '${deploymentPrefix}-appInsights'
  scope: resourceGroup(defaultResourceGroup.name)

  params: {
    appInsightsName: varAppInsightsName
    location: location
    loggingSubscriptionId: loggingSubscriptionId
    loggingResourceGroupName: loggingResourceGroupName
    loggingWorkspaceName: loggingWorkspaceName
    tags: tags
  }
}

// Outputs
output resourceGroupName string = defaultResourceGroup.name
