environment   = "prd"
workload_name = "platform-monitoring"
location      = "uksouth"

subscription_id = "7760848c-794d-4a19-8cb2-52f71a21ac2b"

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
