environment = "dev"
locations   = ["uksouth", "eastus"]

subscription_id = "d68448b0-9947-46d7-8771-baa331a3063a"

geolocation_app_insights = {
  subscription_id     = "d68448b0-9947-46d7-8771-baa331a3063a"
  resource_group_name = "rg-geolocation-dev-uksouth-01"
  name                = "ai-geolocation-dev-uksouth-01"
}

portal_app_insights = {
  subscription_id     = "d68448b0-9947-46d7-8771-baa331a3063a"
  resource_group_name = "rg-portal-core-dev-uksouth-01"
  name                = "ai-portal-core-dev-uksouth-01"
}

test_config = <<-JSON
[
  {
    "App": "fn-portal-event-ingest-dev-uksouth-01-fafcb30ca7e0",
    "AppInsights": "portal",
    "Uri": "https://fn-portal-event-ingest-dev-uksouth-01-fafcb30ca7e0.azurewebsites.net/api/health"
  },
  {
    "App": "app-portal-repo-dev-uksouth-01-ebd9159c6051",
    "AppInsights": "portal",
    "Uri": "https://app-portal-repo-dev-uksouth-01-ebd9159c6051.azurewebsites.net/api/health"
  },
  {
    "App": "fn-portal-repo-func-dev-uksouth-01-be9e6fe6e9c7",
    "AppInsights": "portal",
    "Uri": "https://fn-portal-repo-func-dev-uksouth-01-be9e6fe6e9c7.azurewebsites.net/api/health"
  },
  {
    "App": "app-portal-servers-int-dev-uksouth-01-32s5yslgz4hea",
    "AppInsights": "portal",
    "Uri": "https://app-portal-servers-int-dev-uksouth-01-32s5yslgz4hea.azurewebsites.net/api/health"
  },
  {
    "App": "fn-portal-sync-dev-uksouth-01-f65d076b94fb",
    "AppInsights": "portal",
    "Uri": "https://fn-portal-sync-dev-uksouth-01-f65d076b94fb.azurewebsites.net/api/health"
  },
  {
    "App": "app-geolocation-api-dev-uksouth-01-3omiauqb7et4w",
    "AppInsights": "geolocation",
    "Uri": "https://app-geolocation-api-dev-uksouth-01-3omiauqb7et4w.azurewebsites.net/api/health"
  },
  {
    "App": "app-geolocation-web-dev-uksouth-01-tzcaho2oarnae",
    "AppInsights": "geolocation",
    "Uri": "https://app-geolocation-web-dev-uksouth-01-tzcaho2oarnae.azurewebsites.net/api/health"
  }
]
JSON

log_analytics_subscription_id     = "d68448b0-9947-46d7-8771-baa331a3063a"
log_analytics_resource_group_name = "rg-platform-logging-prd-uksouth-01"
log_analytics_workspace_name      = "log-platform-prd-uksouth-01"

app_service_plan = {
  sku = "Y1"
}

tags = {
  Environment = "dev",
  Workload    = "platform",
  DeployedBy  = "GitHub-Terraform",
  Git         = "https://github.com/frasermolyneux/platform-monitoring-func"
}
