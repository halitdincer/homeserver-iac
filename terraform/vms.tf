# VM 100: Immich - Photo Management
resource "proxmox_virtual_environment_vm" "immich" {
  name        = "immich"
  description = "Immich photo management server"
  node_name   = var.proxmox_node
  vm_id       = 100
  on_boot     = true

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 17408  # 17GB (added 1GB for testing)
  }

  bios = "ovmf"
  machine = "q35"
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    iothread     = true
    size         = 64
    file_format  = "raw"
  }

  efi_disk {
    datastore_id = var.storage_pool
    type         = "4m"
  }

  serial_device {}

  usb {
    host = "0bda:9210"  # Card reader
    usb3 = false
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [
      network_device,
      disk,
      started,
    ]
  }
}

# VM 103: Home Assistant OS
resource "proxmox_virtual_environment_vm" "home_assistant" {
  name        = "haos-16.3"
  description = "Home Assistant OS - Smart home automation"
  node_name   = var.proxmox_node
  vm_id       = 103
  on_boot     = true
  tags        = ["community-script"]

  cpu {
    cores = 2
    type  = "qemu64"  # HAOS uses qemu64
  }

  memory {
    dedicated = 4096  # 4GB
  }

  bios = "ovmf"
  machine = "q35"
  scsi_hardware = "virtio-scsi-pci"
  tablet_device = false

  agent {
    enabled = true
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    size         = 32
    file_format  = "raw"
  }

  efi_disk {
    datastore_id = var.storage_pool
    type         = "4m"
  }

  serial_device {}

  usb {
    host = "1a86:7523"  # Zigbee coordinator
    usb3 = false
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [
      network_device,
      disk,
      started,
      description,  # Ignore the long HTML description
    ]
  }
}

# VM 105: K3s - Lightweight Kubernetes
resource "proxmox_virtual_environment_vm" "k3s" {
  name        = "k3s"
  description = "K3s - Lightweight Kubernetes cluster with ArgoCD"
  node_name   = var.proxmox_node
  vm_id       = 105
  on_boot     = true

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096  # 4GB
  }

  bios = "ovmf"
  machine = "q35"
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    iothread     = true
    size         = 50
    file_format  = "raw"
  }

  efi_disk {
    datastore_id = var.storage_pool
    type         = "4m"
  }

  serial_device {}

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [
      network_device,
      disk,
      started,
    ]
  }
}

