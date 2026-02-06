# Current Infrastructure State

**Last Updated**: 2026-02-06
**Exported from**: Proxmox VE 9.1.1 @ 192.168.2.50

## VMs Overview

| VMID | Name | Status | CPU | RAM | Disk | IP | Purpose |
|------|------|--------|-----|-----|------|----|---------|
| 100 | immich | Running | 4 | 16GB | 64GB | 192.168.2.202 | Photo management |
| 101 | clone-template-VM | Stopped | 2 | 8GB | 64GB | - | Ubuntu template |
| 102 | nginx | Running | 2 | 8GB | 64GB | 192.168.2.10 | Nginx Proxy Manager |
| 103 | haos-16.3 | Running | 2 | 4GB | 32GB | 192.168.2.206 | Home Assistant |

## VM Details

### VM 100: Immich
- **OS**: Ubuntu 24.04.3 LTS
- **Boot**: UEFI (OVMF), Q35 machine type
- **Storage**: SCSI (virtio-scsi-single), iothread enabled
- **Network**: virtio, bridge vmbr0
- **Special**: USB card reader (0bda:9210)
- **Services**:
  - Immich container on port 2283
  - External URL: https://photos.halitdincer.com
- **Auto-start**: Yes

### VM 101: clone-template-VM
- **OS**: Ubuntu 24.04.3 LTS
- **Boot**: UEFI (OVMF), Q35 machine type
- **Storage**: SCSI (virtio-scsi-single), iothread enabled
- **Network**: virtio, bridge vmbr0
- **Purpose**: Template for cloning new Ubuntu VMs
- **Auto-start**: No
- **Status**: Stopped

### VM 102: Nginx Proxy Manager
- **OS**: Ubuntu 24.04.3 LTS
- **Boot**: UEFI (OVMF), Q35 machine type
- **Storage**: SCSI (virtio-scsi-single), iothread enabled
- **Network**: virtio, bridge vmbr0
- **Credentials**: dincer / AbTe0fzg
- **Services**:
  - Nginx Proxy Manager (Docker) on port 81 (admin)
  - Proxies ports 80, 443 to services
  - External URLs:
    - https://nginx.halitdincer.com
    - https://domains.halitdincer.com
- **Auto-start**: Yes
- **Port Forwarding**: Router forwards 80, 443 → 192.168.2.10

### VM 103: Home Assistant OS
- **OS**: Home Assistant OS 16.3
- **Boot**: UEFI (OVMF), Q35 machine type
- **Storage**: SCSI (virtio-scsi-pci), 32GB, SSD emulation, discard enabled
- **Network**: virtio, bridge vmbr0
- **Special**:
  - USB Zigbee coordinator (1a86:7523)
  - No tablet device (HAOS requirement)
- **Services**: Home Assistant on port 8123
- **External URLs**:
  - https://ha.halitdincer.com
  - https://homeassistant.halitdincer.com
- **Auto-start**: Yes
- **Tags**: community-script

## Network Configuration

- **Bridge**: vmbr0 (default)
- **Gateway**: 192.168.2.1 (Bell Home Hub 3000)
- **DNS**: 192.168.2.1, 8.8.8.8
- **Proxmox Host**: 192.168.2.50 (MAC: 18:66:da:10:41:b1)

### IP Assignments
All IPs are statically configured inside the VMs (not DHCP):
- 192.168.2.10 - Nginx Proxy Manager
- 192.168.2.50 - Proxmox VE host
- 192.168.2.202 - Immich
- 192.168.2.206 - Home Assistant

## Storage

- **Storage Pool**: local-lvm (thin provisioning)
- **ISO Storage**: local
- **Used ISO**: ubuntu-24.04.3-live-server-amd64.iso

## External Access

- **Domain**: halitdincer.com (Namecheap)
- **DDNS**: halitdincer.ddns.net (No-IP) → Public IP
- **DNS**: Wildcard CNAME `*.halitdincer.com` → `halitdincer.ddns.net`
- **Port Forwarding**: Router forwards 80, 443 to 192.168.2.10
- **SSL**: Let's Encrypt via Nginx Proxy Manager

## Services Map

```
Internet
  ↓ (80, 443)
Router (192.168.2.1)
  ↓ Port forward
Nginx Proxy Manager (192.168.2.10)
  ├─→ photos.halitdincer.com → 192.168.2.202:2283 (Immich)
  ├─→ ha.halitdincer.com → 192.168.2.206:8123 (Home Assistant)
  ├─→ nginx.halitdincer.com → 192.168.2.10:81 (NPM Admin)
  └─→ proxmox.halitdincer.com → 192.168.2.50:8006 (Proxmox - needs config)
```

## Docker Containers

### On VM 102 (Nginx)
- **nginx-proxy-manager**: Reverse proxy with Let's Encrypt
  - Ports: 80, 443, 81
  - Data: `/opt/nginx-proxy-manager`

### On VM 100 (Immich)
- **immich**: Photo management
  - Port: 2283
  - Data: `/opt/immich` (needs verification)

## USB Device Passthrough

| VMID | Device | Vendor:Product | Purpose |
|------|--------|----------------|---------|
| 100 | Card Reader | 0bda:9210 | SD card import |
| 103 | Zigbee Coordinator | 1a86:7523 | Smart home control |

## Known Issues

1. **proxmox.halitdincer.com** not working - DNS record needs fixing in Namecheap
2. VM 101 (template) is stopped and may need cleanup or conversion to actual template
3. All VMs use CD-ROM mount (Ubuntu ISO) - can be removed if not needed

## Next Steps for IaC Migration

1. ✅ Document current state (this file)
2. ✅ Create Terraform configurations
3. ⏳ Create Ansible playbooks for each service
4. ⏳ Set up Proxmox API token
5. ⏳ Import VMs into Terraform state
6. ⏳ Test state management
7. ⏳ Document Claude usage workflow
