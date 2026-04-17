resource "google_storage_bucket" "demo" {
  name     = "${var.project_id}-demo-bucket"
  location = var.region

  uniform_bucket_level_access = true
}