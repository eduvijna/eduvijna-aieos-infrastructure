variable "name" { type = string }
variable "droplet_ids" { type = list(string) }
variable "vpc_uuid" { type = string }
variable "tags" { type = list(string) }

variable "admin_source_cidrs" {
  type        = list(string)
  description = "Restricted operator admin sources. Must be supplied at pre-apply config time — never hard-code developer/home IPs in Git."
  default     = []
}

variable "s3_source_cidrs" {
  type        = list(string)
  description = "Private VPC (and later App Platform VPC path) sources permitted for S3 API."
}

variable "s3_port" {
  type    = number
  default = 443
}

variable "admin_port" {
  type        = number
  description = "Restricted administrative port (exact path is operational EDR)."
  default     = 22
}

# Intended semantics only. Public internet S3 is denied by omission (no 0.0.0.0/0 inbound for S3).
resource "digitalocean_firewall" "aistor" {
  name        = var.name
  droplet_ids = var.droplet_ids
  tags        = var.tags

  # Normal S3: private sources only.
  dynamic "inbound_rule" {
    for_each = length(var.s3_source_cidrs) > 0 ? [1] : []
    content {
      protocol         = "tcp"
      port_range       = tostring(var.s3_port)
      source_addresses = var.s3_source_cidrs
    }
  }

  # Administrative access: separate restricted operator path.
  dynamic "inbound_rule" {
    for_each = length(var.admin_source_cidrs) > 0 ? [1] : []
    content {
      protocol         = "tcp"
      port_range       = tostring(var.admin_port)
      source_addresses = var.admin_source_cidrs
    }
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

output "firewall_id" {
  value = digitalocean_firewall.aistor.id
}

output "semantics" {
  value = {
    normal_s3             = "private VPC sources required"
    public_internet_s3    = "DENY / no rule"
    administrative_access = "separate restricted operator path"
    vpc_uuid_reference    = var.vpc_uuid
  }
}
