output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github_provider.name
}

output "service_account_email" {
  value = google_service_account.terraform_sa.email
}

output "project_number" {
  value = data.google_project.project.number
}