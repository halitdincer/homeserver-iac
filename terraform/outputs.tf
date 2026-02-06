output "immich_vm_id" {
  description = "Immich VM ID"
  value       = proxmox_virtual_environment_vm.immich.vm_id
}

output "immich_name" {
  description = "Immich VM name"
  value       = proxmox_virtual_environment_vm.immich.name
}

output "nginx_vm_id" {
  description = "Nginx Proxy Manager VM ID"
  value       = proxmox_virtual_environment_vm.nginx.vm_id
}

output "nginx_name" {
  description = "Nginx VM name"
  value       = proxmox_virtual_environment_vm.nginx.name
}

output "home_assistant_vm_id" {
  description = "Home Assistant VM ID"
  value       = proxmox_virtual_environment_vm.home_assistant.vm_id
}

output "home_assistant_name" {
  description = "Home Assistant VM name"
  value       = proxmox_virtual_environment_vm.home_assistant.name
}

output "all_vms" {
  description = "Summary of all VMs"
  value = {
    immich = {
      vmid = proxmox_virtual_environment_vm.immich.vm_id
      name = proxmox_virtual_environment_vm.immich.name
    }
    nginx = {
      vmid = proxmox_virtual_environment_vm.nginx.vm_id
      name = proxmox_virtual_environment_vm.nginx.name
    }
    home_assistant = {
      vmid = proxmox_virtual_environment_vm.home_assistant.vm_id
      name = proxmox_virtual_environment_vm.home_assistant.name
    }
  }
}
