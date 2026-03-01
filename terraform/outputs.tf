output "immich_vm_id" {
  description = "Immich VM ID"
  value       = proxmox_virtual_environment_vm.immich.vm_id
}

output "immich_name" {
  description = "Immich VM name"
  value       = proxmox_virtual_environment_vm.immich.name
}

output "home_assistant_vm_id" {
  description = "Home Assistant VM ID"
  value       = proxmox_virtual_environment_vm.home_assistant.vm_id
}

output "home_assistant_name" {
  description = "Home Assistant VM name"
  value       = proxmox_virtual_environment_vm.home_assistant.name
}

output "k3s_vm_id" {
  description = "K3s VM ID"
  value       = proxmox_virtual_environment_vm.k3s.vm_id
}

output "k3s_name" {
  description = "K3s VM name"
  value       = proxmox_virtual_environment_vm.k3s.name
}

output "devbox_vm_id" {
  description = "devbox VM ID"
  value       = proxmox_virtual_environment_vm.devbox.vm_id
}

output "devbox_name" {
  description = "devbox VM name"
  value       = proxmox_virtual_environment_vm.devbox.name
}

output "all_vms" {
  description = "Summary of all VMs"
  value = {
    immich = {
      vmid = proxmox_virtual_environment_vm.immich.vm_id
      name = proxmox_virtual_environment_vm.immich.name
    }
    home_assistant = {
      vmid = proxmox_virtual_environment_vm.home_assistant.vm_id
      name = proxmox_virtual_environment_vm.home_assistant.name
    }
    devbox = {
      vmid = proxmox_virtual_environment_vm.devbox.vm_id
      name = proxmox_virtual_environment_vm.devbox.name
    }
    k3s = {
      vmid = proxmox_virtual_environment_vm.k3s.vm_id
      name = proxmox_virtual_environment_vm.k3s.name
    }
  }
}
