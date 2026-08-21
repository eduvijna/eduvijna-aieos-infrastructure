terraform {
  required_version = "= 1.12.5"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "= 2.99.1"
    }
  }
}

provider "digitalocean" {
  # Token MUST come from environment / deployment authority (DIGITALOCEAN_TOKEN).
  # Never commit tokens. CI for this repository must NOT hold production tokens.
}
