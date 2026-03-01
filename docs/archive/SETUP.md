# Infrastructure Setup Guide

Complete guide to setting up the homeserver Infrastructure as Code.

## Prerequisites

### 1. Install Required Tools

```bash
# macOS
brew install terraform ansible

# Verify installation
terraform version  # Should be >= 1.0
ansible --version  # Should be >= 2.9
```

### 2. Clone the Repository

```bash
git clone <your-repo-url> ~/homeserver-iac
cd ~/homeserver-iac
```

## Initial Setup

### Step 1: Create Proxmox API Token

SSH into your Proxmox server and create an API token for Terraform:

```bash
ssh root@192.168.2.50

# Create API token (save the output!)
pveum user token add root@pam terraform --privsep 0

# Output will be something like:
# ┌──────────────┬──────────────────────────────────────┐
# │ key          │ value                                │
# ╞══════════════╪══════════════════════════════════════╡
# │ full-tokenid │ root@pam!terraform                   │
# ├──────────────┼──────────────────────────────────────┤
# │ info         │ {"privsep":0}                        │
# ├──────────────┼──────────────────────────────────────┤
# │ value        │ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │
# └──────────────┴──────────────────────────────────────┘

# IMPORTANT: Save the 'value' field - you can't retrieve it later!
```

### Step 2: Configure Terraform Credentials

Create `terraform/terraform.tfvars` from the example:

```bash
cd ~/homeserver-iac/terraform
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Update with your actual token:

```hcl
proxmox_api_url      = "https://192.168.2.50:8006/api2/json"
proxmox_token_id     = "root@pam!terraform"
proxmox_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # From Step 1

proxmox_node    = "pve1"
network_gateway = "192.168.2.1"
network_bridge  = "vmbr0"
dns_servers     = "192.168.2.1 8.8.8.8"
storage_pool    = "local-lvm"
iso_storage     = "local"
```

### Step 3: Initialize Terraform

```bash
cd ~/homeserver-iac/terraform

# Download provider plugins
terraform init

# You should see:
# Terraform has been successfully initialized!
```

### Step 4: Import Existing VMs

Since your VMs already exist, we need to import them into Terraform state:

```bash
# Import each VM (this doesn't change anything, just tracks state)
terraform import proxmox_vm_qemu.immich pve1/qemu/100
terraform import proxmox_vm_qemu.nginx pve1/qemu/102
terraform import proxmox_vm_qemu.home_assistant pve1/qemu/103
terraform import proxmox_vm_qemu.clone_template pve1/qemu/101

# Verify state
terraform state list
```

### Step 5: Verify Configuration Matches

```bash
# This should show NO changes if config matches reality
terraform plan

# If you see changes, review them carefully
# The config may need adjustment to match your actual VMs
```

**Expected output**: `No changes. Your infrastructure matches the configuration.`

If you see differences, you may need to adjust the Terraform config to match your actual VMs.

### Step 6: Configure Ansible

```bash
cd ~/homeserver-iac/ansible

# Copy example config
cp ansible.cfg.example ansible.cfg

# Update inventory if needed
nano inventory/hosts.yml
```

Test Ansible connectivity:

```bash
# Test connection to all hosts
ansible all -i inventory/hosts.yml -m ping

# Test specific host
ansible nginx -i inventory/hosts.yml -m ping
```

## Verification

### Test Terraform

```bash
cd ~/homeserver-iac/terraform

# Check formatting
terraform fmt -check

# Validate configuration
terraform validate

# Preview changes
terraform plan

# View current state
terraform show
```

### Test Ansible

```bash
cd ~/homeserver-iac/ansible

# Check playbook syntax
ansible-playbook playbooks/all.yml --syntax-check

# Dry run (don't make changes)
ansible-playbook playbooks/all.yml --check

# List all hosts
ansible all -i inventory/hosts.yml --list-hosts
```

## Troubleshooting

### "Certificate verify failed"

```bash
# Proxmox uses self-signed cert by default
# In terraform.tfvars, ensure:
pm_tls_insecure = true

# Or install proper SSL cert on Proxmox
```

### "VM already exists"

```bash
# You need to import existing VMs first
terraform import proxmox_vm_qemu.<name> pve1/qemu/<vmid>
```

### "Permission denied"

```bash
# Ensure API token has proper permissions
ssh root@192.168.2.50
pveum role list
pveum user token list root@pam
```

### Ansible connection timeout

```bash
# Verify SSH access
ssh root@192.168.2.202  # Immich
ssh dincer@192.168.2.10  # Nginx (different user!)

# Check firewall
ssh root@192.168.2.50
iptables -L -n
```

## Next Steps

After setup is complete:

1. ✅ Terraform is initialized and VMs are imported
2. ✅ Ansible can connect to all hosts
3. 📖 Read [OPERATIONS.md](OPERATIONS.md) for common tasks
4. 📖 Read [CLAUDE.md](CLAUDE.md) for using with Claude Code
5. 🔒 Commit your changes to git (but NOT terraform.tfvars!)

```bash
# Initialize git repo
cd ~/homeserver-iac
git init
git add .
git commit -m "Initial infrastructure as code setup"

# Add remote and push
git remote add origin <your-repo-url>
git push -u origin main
```

## Security Checklist

- [ ] `terraform.tfvars` is in `.gitignore`
- [ ] API token is stored securely
- [ ] SSH keys are set up (no password auth)
- [ ] Firewall rules are configured
- [ ] Backups are enabled on Proxmox
- [ ] Git repository is private (if using GitHub/GitLab)

## Support

If you encounter issues:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review Proxmox logs: `ssh root@192.168.2.50 "journalctl -u pve-cluster -n 100"`
3. Check Terraform logs: `TF_LOG=DEBUG terraform plan`
4. Ask Claude Code for help! 🤖
