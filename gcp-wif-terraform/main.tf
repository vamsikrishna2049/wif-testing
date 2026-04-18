#########################################
# ENABLE REQUIRED APIS
#########################################

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
}

resource "google_project_service" "iamcredentials" {
  service = "iamcredentials.googleapis.com"
}

resource "google_project_service" "sts" {
  service = "sts.googleapis.com"
}

#########################################
# SERVICE ACCOUNT FOR GITHUB ACTIONS
#########################################

resource "google_service_account" "github_actions" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
}

#########################################
# WORKLOAD IDENTITY POOL
# (Fresh name avoids previous 409 conflict)
#########################################

resource "google_iam_workload_identity_pool" "github_pool" {

  workload_identity_pool_id = var.workload_identity_pool_id

  display_name = "GitHub OIDC Pool"

  description = "Workload Identity Federation Pool for GitHub Actions"

  disabled = false

  depends_on = [
    google_project_service.iam,
    google_project_service.sts
  ]
}

#########################################
# GITHUB OIDC PROVIDER
#########################################

resource "google_iam_workload_identity_pool_provider" "github_provider" {

  workload_identity_pool_id = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id

  workload_identity_pool_provider_id = "github"

  display_name = "GitHub OIDC Provider"

  description = "GitHub Actions OIDC Provider"

  #########################################
  # REQUIRED FOR GITHUB OIDC
  #########################################

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  #########################################

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.workflow"   = "assertion.job_workflow_ref"
  }

  #########################################
  # Safer than workflow matching
  #########################################

  attribute_condition = "attribute.repository == \"vamsikrishna2049/wif-testing\""
}

#########################################
# ALLOW GITHUB TO IMPERSONATE SA
#########################################

resource "google_service_account_iam_member" "wif_user" {

  service_account_id = google_service_account.github_actions.name

  role = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/vamsikrishna2049/wif-testing"
}

#########################################
# ALLOW TOKEN GENERATION
#########################################

resource "google_service_account_iam_member" "token_creator" {

  service_account_id = google_service_account.github_actions.name

  role = "roles/iam.serviceAccountTokenCreator"

  member = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/vamsikrishna2049/wif-testing"
}

#########################################
# OUTPUTS
#########################################

output "workload_identity_provider" {

  value = "projects/${var.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/providers/github"
}

output "service_account_email" {

  value = google_service_account.github_actions.email
}