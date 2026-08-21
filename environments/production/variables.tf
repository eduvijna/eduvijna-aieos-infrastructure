variable "do_project_id" {
  type        = string
  description = "Existing DigitalOcean project ID for AIEOS production (project name AIEOS). Do not create a second production project."
}

variable "do_project_name" {
  type        = string
  description = "Expected production project name (verification only)."
  default     = "AIEOS"
}

variable "vpc_name" {
  type        = string
  description = "Logical name for the NEW dedicated production VPC."
  default     = "aieos-prod-blr1"
}

variable "vpc_region" {
  type        = string
  description = "DigitalOcean region slug for production VPC and AIStor."
  default     = "blr1"
}

variable "vpc_ip_range" {
  type        = string
  description = <<-EOT
    Candidate production VPC CIDR. MUST be explicitly collision-checked against
    existing account VPCs (including default-blr1 10.122.0.0/20 and DOKS
    cluster/service subnets) before any apply. This value is not frozen until
    that proof exists.
  EOT
  default     = "10.130.0.0/20"
}

variable "aistor_droplet_name" {
  type    = string
  default = "aieos-prod-aistor-01"
}

variable "aistor_size" {
  type    = string
  default = "s-2vcpu-4gb"
}

variable "aistor_image" {
  type        = string
  description = "Ubuntu 24.04 LTS distribution slug."
  default     = "ubuntu-24-04-x64"
}

variable "aistor_volume_size_gb" {
  type        = number
  description = "Nominal size per AIStor data Volume (GiB)."
  default     = 190
}

variable "aistor_volume_names" {
  type = list(string)
  default = [
    "aieos-prod-aistor-data-01",
    "aieos-prod-aistor-data-02",
    "aieos-prod-aistor-data-03",
    "aieos-prod-aistor-data-04",
    "aieos-prod-aistor-data-05",
    "aieos-prod-aistor-data-06",
  ]

  validation {
    condition     = length(var.aistor_volume_names) == 6
    error_message = "Bootstrap AIStor requires exactly six dedicated Volumes."
  }
}

variable "aistor_mount_points" {
  type = list(string)
  default = [
    "/srv/aistor/data01",
    "/srv/aistor/data02",
    "/srv/aistor/data03",
    "/srv/aistor/data04",
    "/srv/aistor/data05",
    "/srv/aistor/data06",
  ]

  validation {
    condition     = length(var.aistor_mount_points) == 6
    error_message = "Bootstrap AIStor requires exactly six mount points."
  }
}

variable "primary_bucket_name" {
  type        = string
  description = "Intended literal production primary bucket (documentation / later create)."
  default     = "aieos-assets-prod"
}

variable "tags" {
  type        = list(string)
  description = "Common tags for production AIStor resources."
  default = [
    "aieos",
    "production",
    "bootstrap",
    "aistor",
  ]
}

variable "enable_cloud_resources" {
  type        = bool
  description = <<-EOT
    Hard guard: keep false until Chief Architect authorizes a production apply.
    When false, modules are not instantiated (modeled-only foundation).
  EOT
  default     = false
}
