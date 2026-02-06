# Quick Start Guide

Get your Infrastructure as Code up and running in 5 steps.

## Prerequisites

✅ Proxmox running at 192.168.2.50
✅ VMs already created (100, 102, 103)
✅ Network access to Proxmox
✅ macOS/Linux computer

## Step 1: Install Tools (2 minutes)

```bash
# Install Terraform and Ansible
brew install terraform ansible

# Verify
terraform version  # Should be 1.0+
ansible --version  # Should be 2.9+
```

## Step 2: Create API Token (2 minutes)

```bash
# SSH to Proxmox
ssh root@192.168.2.50

# Create token
pveum user token add root@pam terraform --privsep 0

# Copy the output - you'll need the 'value' field!
# Example: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

## Step 3: Configure Credentials (2 minutes)

```bash
cd ~/homeserver-iac/terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your token
nano terraform.tfvars

# Add your token from Step 2:
proxmox_token_secret = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

# Save and exit (Ctrl+O, Ctrl+X)
```

## Step 4: Initialize Terraform (3 minutes)

```bash
cd ~/homeserver-iac/terraform

# Initialize
terraform init

# Import existing VMs (don't worry, this won't change anything!)
terraform import proxmox_vm_qemu.immich pve1/qemu/100
terraform import proxmox_vm_qemu.nginx pve1/qemu/102
terraform import proxmox_vm_qemu.home_assistant pve1/qemu/103
terraform import proxmox_vm_qemu.clone_template pve1/qemu/101

# Verify (should show NO changes)
terraform plan
```

**Expected output:** `No changes. Your infrastructure matches the configuration.`

## Step 5: Test It! (2 minutes)

Let's make a small change to verify everything works:

```bash
# Edit Immich VM to add 1GB RAM (just as a test)
nano vms.tf

# Find the immich resource, change:
# memory = 16384
# To:
# memory = 17408  # +1GB

# Save and preview
terraform plan

# You should see:
# ~ memory = 16384 -> 17408

# Apply the change
terraform apply
# Type 'yes' when prompted

# Verify it worked
ssh root@192.168.2.50 "qm config 100 | grep memory"
# Should show: memory: 17408

# Revert if you want
# Change back to 16384 in vms.tf
# terraform apply
```

## ✅ You're Done!

Your infrastructure is now managed as code!

## Next Steps

### Configure Ansible (Optional)

```bash
cd ~/homeserver-iac/ansible

# Test connectivity
ansible all -i inventory/hosts.yml -m ping

# If it works, you can deploy services:
ansible-playbook -i inventory/hosts.yml playbooks/nginx-proxy-manager.yml
```

### Set Up Git

```bash
cd ~/homeserver-iac

# Initialize git
git init
git add .
git commit -m "Initial infrastructure as code setup"

# Create GitHub repo and push
git remote add origin https://github.com/yourusername/homeserver-iac.git
git push -u origin main
```

### Update ~/.claude/CLAUDE.md

Add this to your Claude configuration:

```markdown
## Infrastructure as Code

Home server is managed via Terraform + Ansible:
- Repo: ~/homeserver-iac
- Terraform: ~/homeserver-iac/terraform
- Ansible: ~/homeserver-iac/ansible
- Docs: ~/homeserver-iac/docs

When making infrastructure changes:
1. Edit files in ~/homeserver-iac
2. Run `terraform plan` to preview
3. Run `terraform apply` to apply
4. Commit changes to git

See ~/homeserver-iac/docs/CLAUDE.md for detailed guide.
```

## Common Commands

```bash
# Check current state
cd ~/homeserver-iac/terraform
terraform show

# Make changes
nano vms.tf
terraform plan
terraform apply

# Deploy services
cd ~/homeserver-iac/ansible
ansible-playbook -i inventory/hosts.yml playbooks/all.yml

# Check VM status
ssh root@192.168.2.50 "qm list"
```

## Troubleshooting

**"Certificate verification failed"**
→ Check that `pm_tls_insecure = true` is NOT in terraform.tfvars (it's in main.tf provider block)

**"VM already exists"**
→ Run the import commands from Step 4

**"Can't connect to Proxmox"**
→ Test: `ping 192.168.2.50` and `curl -k https://192.168.2.50:8006`

**More help:** See `docs/TROUBLESHOOTING.md`

## What You Can Do Now

**Ask Claude to make changes:**
- "Add 2GB RAM to Immich"
- "Create a new VM for Jellyfin"
- "Update Nginx Proxy Manager configuration"

**Manage infrastructure:**
```bash
cd ~/homeserver-iac
terraform plan   # Preview changes
terraform apply  # Apply changes
```

**Deploy services:**
```bash
cd ~/homeserver-iac/ansible
ansible-playbook -i inventory/hosts.yml playbooks/immich.yml
```

## Documentation

- 📖 [Full Setup Guide](docs/SETUP.md) - Detailed setup instructions
- 🔧 [Operations Guide](docs/OPERATIONS.md) - Common tasks
- 🤖 [Claude Usage Guide](docs/CLAUDE.md) - Using with Claude Code
- 🛠️ [Troubleshooting](docs/TROUBLESHOOTING.md) - Fix common issues
- 📋 [Current State](docs/CURRENT_STATE.md) - Infrastructure inventory

## Need Help?

Just ask Claude! This entire setup is designed to be managed by Claude Code.

Example:
- "Show me the current state of my infrastructure"
- "How do I add a new VM?"
- "What's wrong with my Terraform setup?"

---

**🎉 Congratulations! Your homeserver is now Infrastructure as Code!**

All changes are version controlled, reviewable, and reproducible.
