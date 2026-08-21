variable "project_id" {
  type        = string
  description = "Existing DigitalOcean project UUID for AIEOS production."
}

variable "project_name" {
  type        = string
  description = "Expected project name for verification."
  default     = "AIEOS"
}

data "digitalocean_project" "aieos" {
  id = var.project_id
}

check "project_name_matches" {
  assert {
    condition     = data.digitalocean_project.aieos.name == var.project_name
    error_message = "Configured project_id does not resolve to the expected AIEOS production project name."
  }
}

output "project_id" {
  value = data.digitalocean_project.aieos.id
}

output "project_name" {
  value = data.digitalocean_project.aieos.name
}
