output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "URL of the Workload Identity Provider for GitHub Actions"
}

output "service_account_email" {
  value       = google_service_account.terraform_sa.email
  description = "Email of the Terraform service account"
}

output "workload_identity_pool_id" {
  value       = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  description = "ID of the Workload Identity Pool"
}

output "project_number" {
  value       = data.google_project.project.number
  description = "GCP Project number"
}