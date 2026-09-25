# Manual Steps

After the monitoring stack creates the Key Vault, replace the placeholder values
for `alert-email` and `alert-phone` with the real notification contacts. Terraform
intentionally ignores subsequent value changes so contact rotation remains a
manual secret-management operation.

Do not add workload application secrets to this Key Vault. Runtime secrets such
as Invision task keys belong in the workload runtime Key Vault managed by
`platform-baremetal`.
