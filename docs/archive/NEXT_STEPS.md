# Next Steps - Complete the Setup

You now have a complete Infrastructure as Code setup! Here's what you need to do to activate it.

## 📋 Setup Checklist

### ✅ Already Done

- [x] Repository structure created at `~/homeserver-iac`
- [x] Terraform configurations for all VMs
- [x] Ansible playbooks for services
- [x] Comprehensive documentation
- [x] Setup automation script
- [x] Updated `~/.claude/CLAUDE.md`

### 🔧 You Need to Do

#### 1. Create Proxmox API Token (5 minutes)

```bash
# SSH to Proxmox
ssh root@192.168.2.50

# Create API token
pveum user token add root@pam terraform --privsep 0

# Output will look like:
# ┌──────────────┬──────────────────────────────────────┐
# │ key          │ value                                │
# ├──────────────┼──────────────────────────────────────┤
# │ full-tokenid │ root@pam!terraform                   │
# │ value        │ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │
# └──────────────┴──────────────────────────────────────┘

# ⚠️ SAVE THE 'value' - you can't retrieve it later!
```

#### 2. Configure Terraform Credentials (2 minutes)

```bash
cd ~/homeserver-iac/terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your token from step 1
nano terraform.tfvars

# Update this line with your actual token:
proxmox_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Save and exit (Ctrl+O, Enter, Ctrl+X)
```

#### 3. Run Setup Script (5 minutes)

```bash
cd ~/homeserver-iac
./setup.sh

# This will:
# - Check prerequisites
# - Initialize Terraform
# - Import existing VMs
# - Verify configuration
# - Set up Ansible
```

#### 4. Verify Everything Works (5 minutes)

```bash
# Check Terraform
cd ~/homeserver-iac/terraform
terraform show

# Should show all 4 VMs (100, 101, 102, 103)

# Test a small change (add 1GB RAM to Immich)
nano vms.tf
# Change: memory = 16384
# To:     memory = 17408

terraform plan   # Preview
terraform apply  # Apply

# Revert if you want
# Change back to 16384
# terraform apply
```

#### 5. Set Up Git Repository (10 minutes)

```bash
cd ~/homeserver-iac

# Initialize git
git init
git add .
git commit -m "Initial infrastructure as code setup"

# Create GitHub repository (optional)
# Go to github.com, create new private repo "homeserver-iac"

# Add remote and push
git remote add origin https://github.com/YOUR_USERNAME/homeserver-iac.git
git push -u origin main
```

#### 6. Configure SSH Keys for Ansible (Optional, 10 minutes)

```bash
# Copy SSH keys to VMs for passwordless access
ssh-copy-id root@192.168.2.202  # Immich
ssh-copy-id dincer@192.168.2.10  # Nginx
ssh-copy-id root@192.168.2.206  # Home Assistant (may not work for HAOS)

# Test Ansible
cd ~/homeserver-iac/ansible
ansible all -i inventory/hosts.yml -m ping
```

## 🚀 You're Ready!

Once you've completed the checklist above, you can:

### Make Infrastructure Changes with Claude

Just tell Claude what you want:

**Examples:**
- "Add 2GB RAM to Immich"
- "Create a new VM for Jellyfin media server"
- "Change Nginx VM to use 4 cores"
- "Show me the current infrastructure state"

**Claude will:**
1. Edit the Terraform files
2. Show you the `terraform plan` diff
3. Apply changes after your approval
4. Commit to git

### Make Manual Changes

```bash
# Edit infrastructure
cd ~/homeserver-iac/terraform
nano vms.tf
terraform plan
terraform apply

# Deploy services
cd ~/homeserver-iac/ansible
ansible-playbook -i inventory/hosts.yml playbooks/immich.yml

# Check status
ssh root@192.168.2.50 "qm list"
```

## 📚 Important Files

### Configuration Files
- `~/homeserver-iac/terraform/vms.tf` - VM definitions
- `~/homeserver-iac/terraform/terraform.tfvars` - Credentials (NOT in git)
- `~/homeserver-iac/ansible/inventory/hosts.yml` - Host inventory
- `~/homeserver-iac/ansible/playbooks/` - Service configurations

### Documentation
- `~/homeserver-iac/QUICKSTART.md` - Quick reference
- `~/homeserver-iac/docs/CLAUDE.md` - Complete Claude usage guide
- `~/homeserver-iac/docs/OPERATIONS.md` - Common operations
- `~/homeserver-iac/docs/TROUBLESHOOTING.md` - Fix issues
- `~/.claude/CLAUDE.md` - Global Claude context

## 🎯 First Project Ideas

Try these to get familiar:

1. **Simple Change**: Add 1GB RAM to a VM
2. **Service Update**: Update Immich Docker container
3. **New Service**: Add Jellyfin or another service
4. **Network Change**: Add static IP documentation
5. **Backup**: Set up automated Proxmox backups

## ❓ Get Help

### Quick References

```bash
# Common commands
terraform plan                                    # Preview changes
terraform apply                                   # Apply changes
terraform show                                    # Current state
ansible-playbook -i inventory/hosts.yml <file>   # Deploy service
ssh root@192.168.2.50 "qm list"                  # List VMs
```

### Documentation

```bash
# Read the guides
cat ~/homeserver-iac/QUICKSTART.md
cat ~/homeserver-iac/docs/CLAUDE.md
cat ~/homeserver-iac/docs/OPERATIONS.md
```

### Ask Claude

Claude Code is designed to manage this infrastructure. Just ask:
- "How do I add a new VM?"
- "Show me the current state"
- "What's in my infrastructure?"
- "Deploy Immich with Ansible"

## 🔒 Security Notes

**DO NOT commit to git:**
- ❌ `terraform.tfvars` (has API token)
- ❌ `terraform.tfstate` (sensitive state)
- ❌ SSH private keys
- ❌ Passwords or secrets

**These are already in .gitignore**

**DO commit to git:**
- ✅ All `.tf` files
- ✅ All Ansible playbooks
- ✅ Documentation
- ✅ Example files

## 📊 What You Have Now

```
~/homeserver-iac/
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # Provider config
│   ├── variables.tf       # Input variables
│   ├── vms.tf             # All VM definitions
│   └── outputs.tf         # Outputs
│
├── ansible/               # Configuration Management
│   ├── inventory/         # Host definitions
│   └── playbooks/         # Service configs
│
├── docs/                  # Documentation
│   ├── SETUP.md          # Full setup guide
│   ├── CLAUDE.md         # Claude usage
│   ├── OPERATIONS.md     # Common tasks
│   └── TROUBLESHOOTING.md
│
├── setup.sh               # Automated setup
├── QUICKSTART.md          # Quick reference
└── NEXT_STEPS.md          # This file
```

## 🎉 Success Criteria

You'll know everything is working when:

1. `terraform show` displays all your VMs
2. `terraform plan` shows "No changes needed"
3. You can successfully make a change (add RAM) and apply it
4. Git repository is set up and you can commit/push
5. Claude can read your infrastructure and make changes

## 🚦 Ready to Start?

Run this command to begin:

```bash
cd ~/homeserver-iac
./setup.sh
```

Then follow the prompts!

---

**Questions? Just ask Claude! That's what this setup is for.** 🤖
