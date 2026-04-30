# Terraform invariant tests
#
# These tests protect against accidental changes that would cause Proxmox to
# recreate VMs or break cluster behaviour. They run on every Atlantis PR via
# `terraform test -test-directory=tests` and require no real credentials
# (mock_provider intercepts all provider calls).

mock_provider "proxmox" {}
mock_provider "namecheap" {}

# Cloudflare resources are imported via `import` blocks in dns.tf — mock
# providers can't process imports, so each cloudflare_dns_record needs an
# override_resource that intercepts the import with stub values.
mock_provider "cloudflare" {
  override_resource {
    target = cloudflare_dns_record.wildcard
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.argocd
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.grafana
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.vault
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.proxmox
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.www
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.mx1
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.mx2
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.apple_domain_verification
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.spf
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.dkim
    values = { id = "stub" }
  }
  override_resource {
    target = cloudflare_dns_record.dmarc
    values = { id = "stub" }
  }
}

# Required because these variables have no default and providers are mocked
variables {
  proxmox_password     = "mock"
  vm_default_password  = "mock"
  cloudflare_api_token = "mock"
  namecheap_user_name  = "mock"
  namecheap_api_user   = "mock"
  namecheap_api_key    = "mock"
}

# ── VM IDs ────────────────────────────────────────────────────────────────────
# VMID is part of the Proxmox VM identity. Changing it destroys and recreates
# the VM, losing all data. These assertions make that an explicit, deliberate act.

run "vm_ids_are_fixed" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.immich.vm_id == 100
    error_message = "Immich VMID must stay 100 — changing it recreates the VM and loses photo data"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.home_assistant.vm_id == 103
    error_message = "Home Assistant VMID must stay 103 — changing it recreates the VM"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.devbox.vm_id == 106
    error_message = "devbox VMID must stay 106 — changing it recreates the VM"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.k3s.vm_id == 105
    error_message = "K3s VMID must stay 105 — changing it recreates the VM and takes down the entire cluster"
  }
}

# ── on_boot ───────────────────────────────────────────────────────────────────
# All VMs must start automatically when the Proxmox host boots. Without this,
# a power outage requires manual intervention to start every VM.

run "all_vms_start_on_host_boot" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.immich.on_boot == true
    error_message = "Immich must start on host boot for automatic recovery after power outage"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.home_assistant.on_boot == true
    error_message = "Home Assistant must start on host boot"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.devbox.on_boot == true
    error_message = "devbox must start on host boot"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.k3s.on_boot == true
    error_message = "K3s must start on host boot — it hosts all cluster services (ArgoCD, Vault, ingress, etc.)"
  }
}

# ── DNS safety ────────────────────────────────────────────────────────────────
# Cloudflare zone lookup must target the correct domain. Changing the filter
# would cause all DNS records to be created in the wrong zone.

run "dns_zone_is_correct" {
  command = plan

  assert {
    condition     = data.cloudflare_zone.halitdincer.filter.name == "halitdincer.com"
    error_message = "Cloudflare zone filter must target halitdincer.com — changing this would manage the wrong domain"
  }
}

# ── Registrar safety ───────────────────────────────────────────────────────
# Nameservers must point to Cloudflare. Changing this breaks all DNS resolution.

run "nameservers_point_to_cloudflare" {
  command = plan

  assert {
    condition     = contains(namecheap_domain_records.halitdincer.nameservers, "daphne.ns.cloudflare.com")
    error_message = "Nameservers must include daphne.ns.cloudflare.com — changing this breaks DNS"
  }
}
