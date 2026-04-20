# Proxmox Connection
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://10.10.10.1:8006/api2/json"
}

variable "proxmox_user" {
  description = "Proxmox username"
  type        = string
  default     = "root@pam"
  sensitive   = true
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve1"
}

# Network Configuration
variable "network_gateway" {
  description = "Network gateway"
  type        = string
  default     = "10.10.10.1"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = string
  default     = "10.10.10.1 8.8.8.8"
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""  # Set this in terraform.tfvars
}

# Storage
variable "storage_pool" {
  description = "Default storage pool"
  type        = string
  default     = "local-lvm"
}

variable "iso_storage" {
  description = "ISO storage location"
  type        = string
  default     = "local"
}

# Cloud-init VM credentials
variable "vm_default_password" {
  description = "Default password for cloud-init VMs"
  type        = string
  sensitive   = true
}

# Cloudflare DNS
variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit permissions"
  type        = string
  sensitive   = true
}
