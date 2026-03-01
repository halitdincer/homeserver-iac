# Using with Claude Code

This infrastructure is designed to be managed by Claude Code from any computer.

## Quick Start for Claude

When you ask Claude to make changes to your homeserver, it will:

1. **Read the current configuration** from this repository
2. **Make changes** to Terraform/Ansible files
3. **Show you the diff** for review
4. **Apply changes** after your approval
5. **Commit changes** to git

## Common Tasks

### Adding RAM to a VM

**You say:** "Add 2GB RAM to Immich"

**Claude will:**
```bash
cd ~/homeserver-iac/terraform
# Edit vms.tf, change memory from 16384 to 18432
terraform plan   # Show you the change
terraform apply  # After your approval
git commit -m "Increase Immich RAM to 18GB"
```

### Creating a New VM

**You say:** "Create a new VM for Jellyfin with 4GB RAM and 2 cores"

**Claude will:**
1. Add new resource in `terraform/vms.tf`
2. Run `terraform plan` to preview
3. Run `terraform apply` to create
4. Create Ansible playbook for Jellyfin configuration
5. Deploy services with Ansible
6. Commit everything to git

### Updating Service Configuration

**You say:** "Update Nginx Proxy Manager to add a new proxy host for jellyfin.halitdincer.com"

**Claude will:**
1. SSH into Nginx VM
2. Use NPM API or update config
3. Document changes in Ansible playbook
4. Commit configuration to git

### Checking Infrastructure Status

**You say:** "What's the current state of my homeserver?"

**Claude will:**
```bash
terraform show
ansible all -i ansible/inventory/hosts.yml -m ping
ssh root@192.168.2.50 "pvesh get /cluster/resources --type vm"
```

## How Claude Accesses Your Server

### Option 1: Same Network (You're at Home)

Claude can directly access:
- Proxmox API: `https://192.168.2.50:8006`
- VMs: `192.168.2.10`, `192.168.2.202`, `192.168.2.206`

**Requirement:** Your laptop must be on the same network (192.168.2.x)

### Option 2: Remote Access (You're Away)

Set up one of these:

#### A. Tailscale VPN (Recommended)

```bash
# Install Tailscale on Proxmox
ssh root@192.168.2.50
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# Install on your laptop
brew install tailscale
tailscale up

# Now Claude can access Proxmox from anywhere via Tailscale IP
```

#### B. SSH Tunnel

```bash
# Create tunnel to Proxmox
ssh -L 8006:localhost:8006 root@your-public-ip

# Update terraform.tfvars temporarily:
proxmox_api_url = "https://localhost:8006/api2/json"
```

#### C. Expose Proxmox API (Less Secure)

Add Nginx proxy host for `proxmox-api.halitdincer.com` → `192.168.2.50:8006`

## Repository Structure

```
~/homeserver-iac/
├── terraform/              ← Infrastructure definitions
│   ├── vms.tf             ← VM configurations (EDIT HERE)
│   ├── variables.tf       ← Variables
│   └── terraform.tfvars   ← Secrets (NOT in git)
│
├── ansible/               ← Configuration management
│   ├── inventory/         ← Host definitions
│   └── playbooks/         ← Service configurations
│
└── docs/                  ← Documentation
    ├── SETUP.md          ← Initial setup
    ├── OPERATIONS.md     ← Common operations
    └── CLAUDE.md         ← This file
```

## What Claude Can Change

✅ **Safe to change:**
- VM CPU/RAM/Disk allocations
- Network settings
- Service configurations
- Ansible playbooks
- Documentation

⚠️ **Requires approval:**
- Deleting VMs
- Changing storage
- Network changes that could break connectivity
- Proxmox host configuration

🚫 **Claude won't do without explicit instruction:**
- Delete production data
- Force-destroy resources
- Bypass safety checks

## Workflow Example

### Full Example: Add Jellyfin Media Server

**You:** "I want to add Jellyfin for media streaming. Can you set it up?"

**Claude:**

```bash
# 1. Claude reads current state
cd ~/homeserver-iac
cat terraform/vms.tf

# 2. Creates new VM definition
# Edits terraform/vms.tf to add:

resource "proxmox_vm_qemu" "jellyfin" {
  name   = "jellyfin"
  vmid   = 104
  cores  = 2
  memory = 4096
  # ... rest of config
}

# 3. Shows you the plan
terraform plan
# "Will create VM 104 with 2 cores, 4GB RAM..."

# 4. You approve
# "Yes, looks good"

# 5. Creates VM
terraform apply -auto-approve

# 6. Creates Ansible playbook
cat > ansible/playbooks/jellyfin.yml <<EOF
---
- name: Configure Jellyfin
  hosts: jellyfin
  tasks:
    - name: Install Docker
      # ...
    - name: Deploy Jellyfin container
      # ...
EOF

# 7. Deploys service
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/jellyfin.yml

# 8. Commits everything
git add .
git commit -m "Add Jellyfin media server (VM 104)"
git push
```

**Result:** New Jellyfin VM running at 192.168.2.204 (or similar)

## Tips for Working with Claude

### Be Specific

❌ "Make it faster"
✅ "Add 2 more CPU cores to the Immich VM"

❌ "Fix the network"
✅ "Change Immich VM IP from 192.168.2.202 to 192.168.2.210"

### Provide Context

"I want to add a new service for X. It should be accessible at https://x.halitdincer.com"

Claude will:
- Create VM
- Deploy service
- Update Nginx Proxy Manager
- Set up SSL

### Review Before Applying

Claude will always show you `terraform plan` output before making changes. Review it!

### Incremental Changes

Instead of: "Rebuild everything"
Better: "First add the VM, then we'll configure it"

## Troubleshooting

### Claude can't connect to Proxmox

```bash
# Check network
ping 192.168.2.50

# Check API
curl -k https://192.168.2.50:8006/api2/json

# Check credentials
cat terraform/terraform.tfvars
```

### Terraform state drift

```bash
# Check what changed outside Terraform
terraform plan

# Refresh state
terraform refresh

# Import manual changes
terraform import proxmox_vm_qemu.name pve1/qemu/vmid
```

### Ansible can't connect

```bash
# Test connectivity
ansible all -i ansible/inventory/hosts.yml -m ping

# Check SSH
ssh root@192.168.2.202
ssh dincer@192.168.2.10  # Note: different user!
```

## Security Notes

🔒 **Credentials:**
- Proxmox API token is in `terraform.tfvars` (gitignored)
- SSH keys should be used (no passwords)
- Ansible vault for sensitive data

🔒 **Access:**
- Claude only makes changes you approve
- All changes are version controlled
- Can rollback via git

🔒 **Network:**
- Use VPN (Tailscale) for remote access
- Don't expose Proxmox API publicly without auth
- Keep router firewall enabled

## What's in Git vs Local Only

**In Git (shared):**
- ✅ Terraform configurations
- ✅ Ansible playbooks
- ✅ Documentation
- ✅ Scripts

**Local only (gitignored):**
- ❌ `terraform.tfvars` (secrets)
- ❌ `terraform.tfstate` (sensitive state)
- ❌ Ansible vault passwords
- ❌ SSH private keys

## Claude's Capabilities

When you're on any computer with this repo, Claude can:

1. **Read** current infrastructure state
2. **Modify** VM configurations
3. **Create** new VMs and services
4. **Deploy** applications via Ansible
5. **Document** all changes
6. **Commit** to version control

All you need:
- This git repository
- Network access to Proxmox (via VPN or local network)
- Terraform and Ansible installed

## Quick Reference

```bash
# Check current infrastructure
terraform show

# See what would change
terraform plan

# Apply changes
terraform apply

# Deploy service
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/immich.yml

# Check VM status
ssh root@192.168.2.50 "qm list"

# View VM config
ssh root@192.168.2.50 "qm config 100"
```

## Next Steps

1. ✅ Complete initial setup ([SETUP.md](SETUP.md))
2. ✅ Test with a small change ("Add 1GB RAM to Immich")
3. ✅ Set up remote access (Tailscale recommended)
4. 📖 Learn common operations ([OPERATIONS.md](OPERATIONS.md))
5. 🚀 Start managing your infrastructure as code!

---

**Ready to go! Just tell Claude what you want to change, and it'll handle the rest.** 🤖
