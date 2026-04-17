output "demo_bucket_name" {
  value       = google_storage_bucket.demo.name
  description = "Name of the demo GCS bucket"
}

output "demo_bucket_url" {
  value       = google_storage_bucket.demo.url
  description = "URL of the demo GCS bucket"
}

output "project_id" {
  value       = var.project_id
  description = "GCP Project ID"
}

output "region" {
  value       = var.region
  description = "GCP Region where resources are deployed"
}
