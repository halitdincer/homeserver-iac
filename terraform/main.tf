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
    # namecheap kept ONLY so the `removed` block in dns.tf can forget
    # namecheap_domain_records from state (needs the provider configured to do so).
    # Delete this + the provider block + vars in the follow-up once this applies.
    namecheap = {
      source  = "namecheap/namecheap"
      version = "~> 2.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
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
  insecure = true # Set to false when using valid SSL cert

  ssh {
    agent = false
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Temporary: required only so the `removed` block in dns.tf can forget
# namecheap_domain_records from state. Delete in the follow-up PR once applied.
provider "namecheap" {
  user_name   = var.namecheap_user_name
  api_user    = var.namecheap_api_user
  api_key     = var.namecheap_api_key
  use_sandbox = false
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth_token
}
