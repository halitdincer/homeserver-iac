terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
    namecheap = {
      source  = "namecheap/namecheap"
      version = "~> 2.0"
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

provider "namecheap" {
  user_name   = var.namecheap_user_name
  api_user    = var.namecheap_api_user
  api_key     = var.namecheap_api_key
  use_sandbox = false
}
