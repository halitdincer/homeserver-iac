terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  # Optional: Use local backend for now
  # Later can migrate to remote backend (S3, Terraform Cloud, etc.)
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true  # Set to false when using valid SSL cert

  ssh {
    agent = false
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
