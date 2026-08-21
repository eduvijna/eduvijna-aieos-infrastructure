variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "ip_range" {
  type        = string
  description = "Candidate CIDR. Collision verification is mandatory before apply."
}

resource "digitalocean_vpc" "this" {
  name        = var.name
  region      = var.region
  ip_range    = var.ip_range
  description = "AIEOS dedicated production VPC (BLR1). Not default-blr1."
}

output "vpc_id" {
  value = digitalocean_vpc.this.id
}

output "vpc_urn" {
  value = digitalocean_vpc.this.urn
}

output "ip_range" {
  value = digitalocean_vpc.this.ip_range
}

output "region" {
  value = digitalocean_vpc.this.region
}
