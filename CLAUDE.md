# Home Server Infrastructure as Code

Proxmox VE 9.1.1 home server on a Dell OptiPlex at 192.168.2.50 (node: `pve1`).
Managed with **Terraform** (provisioning + DNS) and **Ansible** (configuration/deployment).
Domain: `halitdincer.com` (Namecheap, DNS managed via Terraform). DDNS via No-IP (`halitdincer.ddns.net`).

## VMs and Services

| VMID | Terraform Resource | IP | Service | Port | URL |
|------|-------------------|-----|---------|------|-----|
| 100 | `proxmox_virtual_environment_vm.immich` | 192.168.2.202 | Immich (photos) | 2283 | photos.halitdincer.com |
| 103 | `proxmox_virtual_environment_vm.home_assistant` | 192.168.2.206 | Home Assistant OS | 8123 | ha.halitdincer.com |
| 104 | `proxmox_virtual_environment_vm.openclaw` | 192.168.2.208 | OpenClaw (AI assistant) | 18789 | openclaw.halitdincer.com |
| 105 | `proxmox_virtual_environment_vm.k3s` | 192.168.2.216 | K3s (ingress, ArgoCD, cert-manager) | 80,443 | argocd.halitdincer.com |

All Ubuntu VMs run 24.04.3 LTS with Docker. Home Assistant runs HAOS 16.3 (no SSH - use REST API).

## Network Topology

```
Internet → Router (192.168.2.1, ports 80/443) → K3s nginx ingress (192.168.2.216)
  ├── photos.halitdincer.com    → 192.168.2.202:2283 (Immich)
  ├── ha.halitdincer.com        → 192.168.2.206:8123 (Home Assistant)
  ├── openclaw.halitdincer.com  → 192.168.2.208:18789 (OpenClaw)
  └── argocd.halitdincer.com    → K3s internal (ArgoCD)

Proxmox host: 192.168.2.50:8006
DNS: *.halitdincer.com → CNAME → halitdincer.ddns.net → public IP (managed in terraform/dns.tf)
SSL: Let's Encrypt via cert-manager (K3s)
```

## Project Structure

```
terraform/
  main.tf          - Provider config (bpg/proxmox v0.70, namecheap/namecheap v2.0, local backend)
  vms.tf           - All VM definitions (EDIT HERE for VM changes)
  dns.tf           - DNS records for halitdincer.com (Namecheap API)
  variables.tf     - Input variables (node, network, storage, Namecheap API)
  outputs.tf       - VM info outputs
  terraform.tfvars - Credentials (GITIGNORED, never commit)

ansible/
  inventory/hosts.yml  - Host inventory with IPs (GITIGNORED)
  playbooks/
    all.yml              - Master playbook (runs all below)
    immich.yml           - Immich deployment
    home-assistant.yml   - Home Assistant management
    openclaw.yml         - OpenClaw deployment
    backup.yml           - Backup configuration
  secrets.yml        - Ansible vault encrypted secrets
  ansible.cfg        - Ansible config (GITIGNORED)

docs/                - Extended documentation (setup, operations, troubleshooting)
```

## Key Commands

```bash
# Terraform - infrastructure changes
cd terraform
terraform plan                    # Preview changes (ALWAYS run first)
terraform apply                   # Apply after review
terraform show                    # Current state

# Ansible - service deployment
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/all.yml
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/immich.yml

# Check VM status via Proxmox
ssh root@192.168.2.50 "qm list"
ssh root@192.168.2.50 "qm config 100"

# Ansible connectivity test
ansible all -i ansible/inventory/hosts.yml -m ping
```

## SSH Access

- **Immich (VM 100)**: `ssh root@192.168.2.202`
- **OpenClaw (VM 104)**: `ssh dincer@192.168.2.208`
- **K3s (VM 105)**: `ssh root@192.168.2.216`
- **Home Assistant (VM 103)**: No SSH. HAOS only - use REST API at port 8123
- **Proxmox host**: `ssh root@192.168.2.50`

## USB Passthrough

- VM 100 (Immich): Card reader `0bda:9210` for SD card photo imports
- VM 103 (Home Assistant): Zigbee coordinator `1a86:7523` for smart home devices

## Rules

- **Never commit secrets**: `terraform.tfvars`, `ansible.cfg`, `hosts.yml`, `*.pem`, `*.key` are gitignored
- **Always `terraform plan` before `terraform apply`**: Show the plan to the user for approval
- **Don't delete VMs or data** without explicit user confirmation
- **Ansible vault** for sensitive data: `ansible-vault edit ansible/secrets.yml`
- **All VMs use static IPs** configured inside the VM (not DHCP)
- **Lifecycle ignores**: All VMs ignore changes to `network_device`, `disk`, and `started` in Terraform to avoid drift issues
- When adding a new service: create VM in `terraform/vms.tf`, add to `ansible/inventory/hosts.yml`, create playbook in `ansible/playbooks/`
- **DNS changes**: Edit `terraform/dns.tf`. Namecheap API has rate limits — avoid frequent plan/apply cycles.

## Terraform Provider Details

- Provider: `bpg/proxmox` v0.70 (resource type: `proxmox_virtual_environment_vm`)
- Provider: `namecheap/namecheap` v2.0 (resource type: `namecheap_domain_records`)
- Auth: username/password via `terraform.tfvars` (root@pam for Proxmox, API key for Namecheap)
- SSL: insecure mode (self-signed Proxmox cert)
- Backend: local state file
- All VMs: UEFI (OVMF), Q35 machine, virtio network, storage on `local-lvm`
