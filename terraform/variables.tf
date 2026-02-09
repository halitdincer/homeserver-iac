# Proxmox Connection
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.2.50:8006/api2/json"
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

# Optional: API Token (not currently used)
variable "proxmox_token_id" {
  description = "Proxmox API token ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  default     = ""
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
  default     = "192.168.2.1"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = string
  default     = "192.168.2.1 8.8.8.8"
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

# Namecheap DNS
variable "namecheap_user_name" {
  description = "Namecheap account username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "namecheap_api_user" {
  description = "Namecheap API user (usually same as username)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "namecheap_api_key" {
  description = "Namecheap API key"
  type        = string
  default     = ""
  sensitive   = true
}
