# Terraform invariant tests
#
# These tests protect against accidental changes that would cause Proxmox to
# recreate VMs or break cluster behaviour. They run on every Atlantis PR via
# `terraform test -test-directory=tests` and require no real credentials
# (mock_provider intercepts all provider calls).

mock_provider "proxmox" {}
mock_provider "namecheap" {}

# Required because these variables have no default and Proxmox/Namecheap are mocked
variables {
  proxmox_password    = "mock"
  vm_default_password = "mock"
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
# OVERWRITE mode means Terraform is the sole source of truth for all DNS records.
# Switching to MERGE would silently leave orphaned records that could conflict
# with new ones. Changing the domain would redirect all traffic elsewhere.

run "dns_config_is_safe" {
  command = plan

  assert {
    condition     = namecheap_domain_records.halitdincer.domain == "halitdincer.com"
    error_message = "DNS resource must manage halitdincer.com — changing this would stop managing your domain"
  }

  assert {
    condition     = namecheap_domain_records.halitdincer.mode == "OVERWRITE"
    error_message = "DNS mode must be OVERWRITE so Terraform is the sole source of truth for all records"
  }
}
