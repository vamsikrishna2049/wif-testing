data "google_project" "project" {
  project_id = var.project_id
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "iam.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])

  project = var.project_id
  service = each.value
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool-2"
  display_name              = "GitHub Pool"
}

# Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"

  display_name = "GitHub Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "attribute.repository == \"${var.github_repo}\""
}

# Service Account
resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Terraform SA"
}

# Allow GitHub to impersonate SA
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.terraform_sa.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_repo}"
}

# Minimal roles (adjust later)
resource "google_project_iam_member" "sa_roles" {
  for_each = toset([
    "roles/compute.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountUser"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}