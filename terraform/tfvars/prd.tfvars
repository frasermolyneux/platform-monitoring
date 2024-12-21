environment = "prd"
locations   = ["uksouth", "eastus", "westeurope", "eastasia", "southindia"]

subscription_id = "7760848c-794d-4a19-8cb2-52f71a21ac2b"

geolocation_app_insights = {
  subscription_id     = "d3b204ab-7c2b-47f7-8d5a-de19e85591e7"
  resource_group_name = "rg-geolocation-prd-uksouth-01"
  name                = "ai-geolocation-prd-uksouth-01"
}

portal_app_insights = {
  subscription_id     = "32444f38-32f4-409f-889c-8e8aa2b5b4d1"
  resource_group_name = "rg-portal-core-prd-uksouth-01"
  name                = "ai-portal-core-prd-uksouth-01"
}

test_config = <<-JSON
[
  {
    "App": "fn-portal-event-ingest-prd-uksouth-01-0a313c960b27",
    "AppInsights": "portal",
    "Uri": "https://fn-portal-event-ingest-prd-uksouth-01-0a313c960b27.azurewebsites.net/api/health"
  },
  {
    "App": "app-portal-repo-prd-uksouth-01-b8f876e0fb09",
    "AppInsights": "portal",
    "Uri": "https://app-portal-repo-prd-uksouth-01-b8f876e0fb09.azurewebsites.net/api/health"
  },
  {
    "App": "fn-portal-repo-func-prd-uksouth-01-f72fbef87dc5",
    "AppInsights": "portal",
    "Uri": "https://fn-portal-repo-func-prd-uksouth-01-f72fbef87dc5.azurewebsites.net/api/health"
  },
  {
    "App": "app-portal-servers-int-prd-uksouth-01-bxxyivgotrxya",
    "AppInsights": "portal",
    "Uri": "https://app-portal-servers-int-prd-uksouth-01-bxxyivgotrxya.azurewebsites.net/api/health"
  },
  {
    "App": "fn-portal-sync-prd-uksouth-01-e7b4c78e276d",
    "AppInsights": "portal",
    "Uri": "https://fn-portal-sync-prd-uksouth-01-e7b4c78e276d.azurewebsites.net/api/health"
  },
  {
    "App": "app-portal-web-prd-uksouth-01-l6supxzf6itfq",
    "AppInsights": "portal",
    "Uri": "https://app-portal-web-prd-uksouth-01-l6supxzf6itfq.azurewebsites.net/api/health"
  },
  {
    "App": "app-geolocation-api-prd-uksouth-01-queggvl6v5yta",
    "AppInsights": "geolocation",
    "Uri": "https://app-geolocation-api-prd-uksouth-01-queggvl6v5yta.azurewebsites.net/api/health"
  },
  {
    "App": "app-geolocation-web-prd-uksouth-01-ndrrqvrn34qke",
    "AppInsights": "geolocation",
    "Uri": "https://app-geolocation-web-prd-uksouth-01-ndrrqvrn34qke.azurewebsites.net/api/health"
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
  Environment = "prd",
  Workload    = "platform",
  DeployedBy  = "GitHub-Terraform",
  Git         = "https://github.com/frasermolyneux/platform-monitoring-func"
}
