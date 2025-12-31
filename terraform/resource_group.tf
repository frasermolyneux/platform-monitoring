locals {
  platform_monitoring_resource_groups = {
    for location in var.locations :
    location => data.terraform_remote_state.platform_workloads.outputs.workload_resource_groups[var.workload_name][var.environment].resource_groups[lower(location)].name
  }
}
