environment   = "prd"
workload_name = "platform-monitoring"
locations     = ["uksouth"]

subscription_id = "7760848c-794d-4a19-8cb2-52f71a21ac2b"

subscriptions = {
  sub-fm-geolocation-prd = {
    name            = "sub-fm-geolocation-prd"
    subscription_id = "d3b204ab-7c2b-47f7-8d5a-de19e85591e7"
  },
  sub-mx-consulting-prd = {
    name            = "sub-mx-consulting-prd"
    subscription_id = "655da25d-da46-40c0-8e81-5debe2dcd024"
  },
  sub-platform-connectivity = {
    name            = "sub-platform-connectivity"
    subscription_id = "db34f572-8b71-40d6-8f99-f29a27612144"
  },
  sub-platform-identity = {
    name            = "sub-platform-identity"
    subscription_id = "c391a150-f992-41a6-bc81-ebc22bc64376"
  },
  sub-platform-management = {
    name            = "sub-platform-management"
    subscription_id = "7760848c-794d-4a19-8cb2-52f71a21ac2b"
  },
  sub-platform-strategic = {
    name            = "sub-platform-strategic"
    subscription_id = "903b6685-c12a-4703-ac54-7ec1ff15ca43"
  },
  sub-talkwithtiles-prd = {
    name            = "sub-talkwithtiles-prd"
    subscription_id = "e1e5de62-3573-4b44-a52b-0f1431675929"
  },
  sub-xi-demomanager-prd = {
    name            = "sub-xi-demomanager-prd"
    subscription_id = "845766d6-b73f-49aa-a9f6-eaf27e20b7a8"
  },
  sub-xi-portal-prd = {
    name            = "sub-xi-portal-prd"
    subscription_id = "32444f38-32f4-409f-889c-8e8aa2b5b4d1"
  },
  sub-finances-prd = {
    name            = "sub-finances-prd"
    subscription_id = "957a7d34-8562-4098-bb4c-072e08386d07"
  },
  sub-molyneux-me-prd = {
    name            = "sub-molyneux-me-prd"
    subscription_id = "3cc59319-eb1e-4b52-b19e-09a49f9db2e7"
  }
}

tags = {
  Environment = "prd",
  Workload    = "platform-monitoring",
  DeployedBy  = "GitHub-Terraform",
  Git         = "https://github.com/frasermolyneux/platform-monitoring"
}

platform_workloads_state = {
  resource_group_name  = "rg-tf-platform-workloads-prd-uksouth-01"
  storage_account_name = "sadz9ita659lj9xb3"
  container_name       = "tfstate"
  key                  = "terraform.tfstate"
  subscription_id      = "7760848c-794d-4a19-8cb2-52f71a21ac2b"
  tenant_id            = "e56a6947-bb9a-4a6e-846a-1f118d1c3a14"
}
