data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "apis" {

  for_each = toset([
    "iam.googleapis.com",
    "sts.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

resource "google_iam_workload_identity_pool" "github_pool" {

  project = var.project_id

  workload_identity_pool_id = "github-pool-0"

  display_name = "GitHub Pool"

  depends_on = [
    google_project_service.apis
  ]
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {

  project = var.project_id

  workload_identity_pool_id = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id

  workload_identity_pool_provider_id = "github"

  display_name = "GitHub Provider"

  depends_on = [
    google_project_service.apis,
    google_iam_workload_identity_pool.github_pool
  ]

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.actor"      = "assertion.actor"
    "attribute.workflow"   = "assertion.workflow"
  }

  attribute_condition = <<EOT
attribute.repository == "${var.github_repo}" &&
attribute.ref == "refs/heads/main" &&
attribute.workflow == ".github/workflows/terraform.yml"
EOT

}

resource "google_service_account" "terraform_sa" {

  project = var.project_id

  account_id = "terraform-sa"

  display_name = "Terraform Service Account"

  depends_on = [
    google_project_service.apis
  ]
}

resource "google_service_account_iam_member" "wif_user" {

  service_account_id = google_service_account.terraform_sa.name

  role = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_repo}"

}

resource "google_service_account_iam_member" "token_creator" {

  service_account_id = google_service_account.terraform_sa.name

  role = "roles/iam.serviceAccountTokenCreator"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_repo}"

}

resource "google_project_iam_member" "sa_roles" {

  for_each = toset([
    "roles/storage.admin",
    "roles/compute.admin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator"
  ])

  project = var.project_id

  role = each.value

  member = "serviceAccount:${google_service_account.terraform_sa.email}"

}