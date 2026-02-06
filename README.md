# Homeserver Infrastructure as Code

Complete Infrastructure as Code setup for Proxmox home server.

## 🏗️ Architecture

- **Proxmox VE**: Dell OptiPlex at 192.168.2.50
- **Management**: Terraform + Ansible
- **VMs**: Immich, Nginx Proxy Manager, Home Assistant
- **Domain**: halitdincer.com (Namecheap)
- **DDNS**: halitdincer.ddns.net (No-IP)

## 📁 Repository Structure

```
homeserver-iac/
├── terraform/          # Infrastructure definitions
│   ├── main.tf        # Provider & backend
│   ├── variables.tf   # Input variables
│   ├── outputs.tf     # Outputs
│   ├── vms.tf         # VM definitions
│   └── network.tf     # Network configuration
├── ansible/           # Configuration management
│   ├── playbooks/     # Service playbooks
│   ├── roles/         # Reusable roles
│   └── inventory/     # Host inventory
└── docs/              # Documentation
```

## 🚀 Quick Start

### Prerequisites

```bash
# Install tools
brew install terraform ansible

# Clone repository
git clone <repo-url> ~/homeserver-iac
cd ~/homeserver-iac
```

### Setup Credentials

1. Create `terraform/terraform.tfvars`:
```hcl
proxmox_api_url = "https://192.168.2.50:8006/api2/json"
proxmox_token_id = "root@pam!terraform"
proxmox_token_secret = "your-token-here"
```

2. Create `ansible/inventory/hosts.yml`:
```yaml
all:
  hosts:
    immich:
      ansible_host: 192.168.2.202
    nginx:
      ansible_host: 192.168.2.10
```

### Deploy Infrastructure

```bash
# Initialize Terraform
cd terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# Configure VMs with Ansible
cd ../ansible
ansible-playbook -i inventory/hosts.yml playbooks/all.yml
```

## 📖 Documentation

See `docs/` directory for detailed documentation:
- [Setup Guide](docs/SETUP.md) - Initial setup and configuration
- [Operations](docs/OPERATIONS.md) - Common operations and tasks
- [Claude Usage](docs/CLAUDE.md) - How Claude can use this repo
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues

## 🤖 Using with Claude

This repository is designed to be used by Claude Code from any computer:

```bash
# Claude can make changes like:
"Add 2GB RAM to Immich VM"
"Create new VM for Jellyfin"
"Update Nginx Proxy Manager configuration"
```

All changes are version controlled and reviewable.

## 🔒 Security

- Never commit `terraform.tfvars` or credentials
- Use API tokens instead of passwords
- Keep secrets in `.gitignore`d files
- Review all changes before applying

## 📝 Current Infrastructure

### VMs
- **VM 100**: Immich (4 CPU, 16GB RAM, 64GB disk) - 192.168.2.202
- **VM 101**: clone-template-VM (stopped) - Template
- **VM 102**: Nginx Proxy Manager (2 CPU, 8GB RAM, 64GB disk) - 192.168.2.10
- **VM 103**: Home Assistant (2 CPU, 4GB RAM, 32GB disk) - 192.168.2.206

### Services
- Immich: https://photos.halitdincer.com
- Nginx Proxy Manager: https://nginx.halitdincer.com
- Home Assistant: https://ha.halitdincer.com

## 🛠️ Maintenance

```bash
# Update VM configuration
vim terraform/vms.tf
terraform plan
terraform apply

# Update service configuration
vim ansible/playbooks/immich.yml
ansible-playbook -i inventory/hosts.yml playbooks/immich.yml

# Commit changes
git add .
git commit -m "Update Immich configuration"
git push
```

## 📚 Resources

- [Terraform Proxmox Provider](https://github.com/Telmate/terraform-provider-proxmox)
- [Ansible Documentation](https://docs.ansible.com/)
- [Proxmox VE API](https://pve.proxmox.com/wiki/Proxmox_VE_API)
