variable "droplet_name" { type = string }
variable "region" { type = string }
variable "size" { type = string }
variable "image" { type = string }
variable "vpc_uuid" { type = string }
variable "project_id" { type = string }
variable "volume_names" { type = list(string) }
variable "volume_size_gb" { type = number }
variable "mount_points" { type = list(string) }
variable "tags" { type = list(string) }

locals {
  volume_map = {
    for idx, name in var.volume_names :
    name => {
      index       = idx
      mount_point = var.mount_points[idx]
    }
  }
}

check "six_volumes_and_mounts" {
  assert {
    condition = (
      length(var.volume_names) == 6 &&
      length(var.mount_points) == 6
    )
    error_message = "Bootstrap AIStor requires exactly six volumes and six mount points."
  }
}

resource "digitalocean_droplet" "aistor" {
  name     = var.droplet_name
  region   = var.region
  size     = var.size
  image    = var.image
  vpc_uuid = var.vpc_uuid
  tags     = var.tags

  # No cloud-init secrets. TLS keys and credentials remain outside OpenTofu state.
  # Monitoring/backups decisions are later EDRs.
}

resource "digitalocean_volume" "data" {
  for_each = local.volume_map

  region                  = var.region
  name                    = each.key
  size                    = var.volume_size_gb
  initial_filesystem_type = "xfs"
  description             = "AIEOS Bootstrap AIStor data device ${each.value.index + 1}/6 → ${each.value.mount_point}"
  tags                    = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_volume_attachment" "data" {
  for_each = digitalocean_volume.data

  droplet_id = digitalocean_droplet.aistor.id
  volume_id  = each.value.id
}

resource "digitalocean_project_resources" "aistor" {
  project = var.project_id
  resources = concat(
    [digitalocean_droplet.aistor.urn],
    [for v in digitalocean_volume.data : v.urn]
  )
}

output "droplet_id" {
  value = digitalocean_droplet.aistor.id
}

output "droplet_urn" {
  value = digitalocean_droplet.aistor.urn
}

output "volume_ids" {
  value = { for k, v in digitalocean_volume.data : k => v.id }
}

output "volume_filesystem_uuids" {
  description = "Prefer filesystem UUID for durable mount authority (populated after format/attach)."
  value       = { for k, v in digitalocean_volume.data : k => v.filesystem_uuid }
}

output "mount_convention" {
  value = {
    for name, meta in local.volume_map :
    name => {
      mount_point     = meta.mount_point
      filesystem_type = "xfs"
      identity_rule   = "filesystem UUID — never /dev/sdX positional identity"
    }
  }
}

output "fail_closed_mount_requirements" {
  value = [
    "all six devices present",
    "all six expected mountpoints mounted",
    "filesystem type XFS",
    "filesystem/device identity matches expected UUID mapping",
    "no root-disk directory fallback",
    "no empty-directory fallback",
    "no nofail that allows AIStor to start incomplete",
  ]
}
