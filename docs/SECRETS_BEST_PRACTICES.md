# Better Secret Management for Home Servers

## 🏠 Homelab Context

Unlike enterprise environments, homelabs need to balance:
- ✅ **Security** - Protect against real threats
- ✅ **Usability** - Easy for you to use daily
- ✅ **Cost** - Free/cheap solutions
- ✅ **Simplicity** - Not overly complex

## 🎯 Recommended Improvements (In Priority Order)

### 1. SSH Keys Instead of Passwords ⭐ (DO THIS FIRST)

**Why:** Most important security improvement for homelabs

**Current State:**
```bash
ssh dincer@192.168.2.10  # Asks for password: AbTe0fzg
ansible needs password authentication
```

**Better:**
```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "homeserver-access"

# Copy to all your VMs
ssh-copy-id root@192.168.2.202  # Immich
ssh-copy-id dincer@192.168.2.10  # Nginx
ssh-copy-id root@192.168.2.206  # Home Assistant

# Now passwordless!
ssh root@192.168.2.202  # No password needed ✅
```

**Benefits:**
- 🔒 More secure than passwords
- ⚡ Faster (no typing)
- 🤖 Required for Ansible automation
- 🚫 Can't be brute-forced

**Setup Time:** 5 minutes

### 2. Environment Variables for Terraform 🌟

**Instead of storing password in file:**

**Current:**
```hcl
# terraform/terraform.tfvars (on disk)
proxmox_password = "AbTe0fzg"
```

**Better:**
```bash
# Add to ~/.zshrc or ~/.bashrc
export TF_VAR_proxmox_password="AbTe0fzg"
export TF_VAR_proxmox_user="root@pam"
export TF_VAR_proxmox_api_url="https://192.168.2.50:8006/api2/json"

# Then terraform.tfvars can be minimal or empty
```

**Benefits:**
- 🔒 Password in memory, not on disk
- 🗑️ Can delete terraform.tfvars entirely
- 🔄 Works across multiple projects
- 💻 Survives git clean commands

**Cons:**
- Need to source profile each terminal session
- Claude needs you to provide it each time

**Setup Time:** 2 minutes

### 3. Use macOS Keychain for Secrets 🍎

**macOS has a built-in secret store!**

```bash
# Store Proxmox password in Keychain
security add-generic-password -a "$(whoami)" -s "proxmox-password" -w "AbTe0fzg"

# Retrieve it in scripts/Terraform
export TF_VAR_proxmox_password=$(security find-generic-password -a "$(whoami)" -s "proxmox-password" -w)

# Add to ~/.zshrc
alias tf-env='export TF_VAR_proxmox_password=$(security find-generic-password -a "$(whoami)" -s "proxmox-password" -w)'
```

**Benefits:**
- 🔒 Encrypted by macOS
- 🔐 Protected by your user password
- 💾 Survives restarts
- 🍎 Native macOS integration

**Setup Time:** 5 minutes

### 4. Ansible Vault for Service Credentials 🔐

**For passwords used in Ansible playbooks:**

```bash
# Create encrypted vault
ansible-vault create ansible/secrets.yml

# It will ask for a vault password, then open editor:
---
npm_admin_email: admin@example.com
npm_admin_password: super_secret_password
immich_db_password: another_secret

# Use in playbooks
- name: Deploy Nginx Proxy Manager
  hosts: nginx
  vars_files:
    - secrets.yml
  tasks:
    - name: Configure NPM
      # Use {{ npm_admin_password }}
```

**Run playbooks:**
```bash
ansible-playbook playbook.yml --ask-vault-pass
# Or store vault password:
echo "vault_password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
ansible-playbook playbook.yml --vault-password-file ~/.ansible_vault_pass
```

**Benefits:**
- 🔒 Encrypted secrets can be committed to git
- 🔑 Password protected
- 📦 Industry standard
- 🤝 Shareable with team

**Setup Time:** 10 minutes

### 5. 1Password CLI (If you use 1Password) 💎

**Best option if you already pay for 1Password:**

```bash
# Install
brew install --cask 1password-cli

# Store in 1Password, retrieve in scripts
export TF_VAR_proxmox_password=$(op read "op://Homelab/Proxmox/password")

# In Terraform
# Password automatically fetched from 1Password
```

**Benefits:**
- 🏢 Professional-grade
- 📱 Sync across devices
- 👨‍👩‍👧‍👦 Share with family
- 🔄 Automatic rotation support
- 📊 Audit logs

**Cons:**
- 💰 Costs $3-5/month
- Requires 1Password subscription

**Setup Time:** 15 minutes (if you have 1Password)

### 6. Hardware Security Keys 🔑

**For ultra-secure authentication:**

```bash
# Use YubiKey or similar for SSH
# Add to ~/.ssh/config
Host 192.168.2.*
    IdentityAgent /path/to/yubikey-agent

# Proxmox supports 2FA
# Add hardware key as second factor
```

**Benefits:**
- 🔐 Physical security
- 🚫 Can't be stolen remotely
- 💪 Phishing resistant

**Cons:**
- 💰 Hardware cost ($25-50)
- 🔌 Need physical key present

### 7. Git Hooks to Prevent Leaks 🪝

**Automatically check for secrets before commit:**

```bash
# Install git-secrets
brew install git-secrets

# Setup in your repo
cd ~/homeserver-iac
git secrets --install
git secrets --register-aws  # Block AWS keys
git secrets --add 'password\s*=\s*.+'  # Block password lines
git secrets --add 'AbTe0fzg'  # Block your actual password

# Now commits with secrets will be blocked
git commit -m "test"
# Error: Prevented commit with secret!
```

**Benefits:**
- 🛡️ Prevents accidental commits
- 🤖 Automatic checking
- 🔍 Scans entire repo history

**Setup Time:** 5 minutes

### 8. Encrypted Home Directory 🔐

**macOS FileVault (you might already have this):**

```bash
# Check if enabled
fdesetup status

# If not enabled:
# System Settings > Privacy & Security > FileVault > Turn On
```

**Benefits:**
- 🔒 Entire disk encrypted
- 🔐 Protects all secrets if laptop stolen
- 🍎 Native macOS feature
- ⚡ Transparent (no performance impact)

**Setup Time:** 30 minutes (one-time encryption)

## 🏗️ Practical Setup for Your Homelab

### Option A: Simple & Secure (Recommended)

**Best for most homelabs:**

1. **SSH Keys** ✅
   ```bash
   ssh-keygen -t ed25519
   ssh-copy-id root@192.168.2.202
   ssh-copy-id dincer@192.168.2.10
   ssh-copy-id root@192.168.2.206
   ```

2. **macOS Keychain for Terraform** ✅
   ```bash
   security add-generic-password -a "$(whoami)" -s "proxmox-password" -w "AbTe0fzg"

   # Add to ~/.zshrc:
   export TF_VAR_proxmox_password=$(security find-generic-password -a "$(whoami)" -s "proxmox-password" -w)
   ```

3. **Git Hooks** ✅
   ```bash
   brew install git-secrets
   cd ~/homeserver-iac
   git secrets --install
   git secrets --add 'AbTe0fzg'
   ```

**Total Time:** 15 minutes
**Security Level:** ⭐⭐⭐⭐ (Excellent for homelab)

### Option B: Power User

**For advanced users or sensitive data:**

All of Option A, plus:

4. **Ansible Vault** for service passwords
5. **1Password CLI** if you use 1Password
6. **Hardware 2FA** for Proxmox

**Total Time:** 1 hour
**Security Level:** ⭐⭐⭐⭐⭐ (Enterprise-grade)

### Option C: Minimalist

**Bare minimum improvement:**

1. **SSH Keys only**
2. **Keep current terraform.tfvars** (it's already gitignored)
3. **Enable FileVault** on macOS

**Total Time:** 10 minutes
**Security Level:** ⭐⭐⭐ (Good enough for private homelab)

## 🔄 Migration Guide

### Step 1: Set Up SSH Keys (NOW)

```bash
# Generate key
ssh-keygen -t ed25519 -C "homeserver" -f ~/.ssh/homeserver_ed25519

# Add to ssh config
cat >> ~/.ssh/config << 'EOF'
Host homeserver-*
    User root
    IdentityFile ~/.ssh/homeserver_ed25519

Host homeserver-immich
    HostName 192.168.2.202

Host homeserver-nginx
    HostName 192.168.2.10
    User dincer

Host homeserver-ha
    HostName 192.168.2.206
EOF

# Copy keys
ssh-copy-id -i ~/.ssh/homeserver_ed25519 root@192.168.2.202
ssh-copy-id -i ~/.ssh/homeserver_ed25519 dincer@192.168.2.10
ssh-copy-id -i ~/.ssh/homeserver_ed25519 root@192.168.2.206

# Test
ssh homeserver-immich  # Should work without password!
```

### Step 2: Move Terraform Secrets to Keychain

```bash
# Store in Keychain
security add-generic-password \
  -a "$(whoami)" \
  -s "proxmox-password" \
  -w "AbTe0fzg" \
  -j "Proxmox root password for Terraform"

# Add to ~/.zshrc
echo '
# Proxmox Terraform Credentials
export TF_VAR_proxmox_password=$(security find-generic-password -a "$(whoami)" -s "proxmox-password" -w 2>/dev/null)
export TF_VAR_proxmox_user="root@pam"
export TF_VAR_proxmox_api_url="https://192.168.2.50:8006/api2/json"
' >> ~/.zshrc

# Reload
source ~/.zshrc

# Test
echo $TF_VAR_proxmox_password  # Should show: AbTe0fzg

# Update Terraform to use env vars (already configured!)
cd ~/homeserver-iac/terraform
terraform plan  # Should work!

# Optional: Remove terraform.tfvars (secrets now in Keychain)
# rm terraform.tfvars  # Only if env vars work!
```

### Step 3: Update Ansible for SSH Keys

```bash
# Update ansible.cfg
cat > ~/homeserver-iac/ansible/ansible.cfg << 'EOF'
[defaults]
inventory = inventory/hosts.yml
host_key_checking = False
private_key_file = ~/.ssh/homeserver_ed25519
remote_user = root

[privilege_escalation]
become = True
become_method = sudo
become_user = root
EOF

# Test
cd ~/homeserver-iac/ansible
ansible all -i inventory/hosts.yml -m ping
# Should work without password!
```

### Step 4: Set Up Git Secrets

```bash
brew install git-secrets
cd ~/homeserver-iac
git secrets --install
git secrets --add 'AbTe0fzg'
git secrets --add 'password\s*=\s*"[^"]*"'

# Test
echo "password = \"AbTe0fzg\"" > test.txt
git add test.txt
git commit -m "test"
# Should be blocked!
rm test.txt
```

## 📊 Security Comparison

| Method | Security | Usability | Cost | Setup Time |
|--------|----------|-----------|------|------------|
| **Current (tfvars)** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Free | 0 min |
| **SSH Keys** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Free | 5 min |
| **Env Variables** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Free | 2 min |
| **macOS Keychain** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Free | 5 min |
| **Ansible Vault** | ⭐⭐⭐⭐ | ⭐⭐⭐ | Free | 10 min |
| **1Password CLI** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | $3-5/mo | 15 min |
| **Hardware Keys** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | $25-50 | 30 min |

## 🎯 My Recommendation for You

**Start with this (30 minutes total):**

1. ✅ **SSH Keys** - Most important
2. ✅ **macOS Keychain** - Better than plain files
3. ✅ **Git Hooks** - Prevent accidents
4. ✅ **FileVault** - Encrypt disk (if not already)

**Later (when needed):**

5. 📦 **Ansible Vault** - When deploying services with passwords
6. 💎 **1Password** - If managing many servers

## 🔍 Audit Your Current Setup

```bash
cd ~/homeserver-iac

# Check what secrets exist
echo "=== Secrets Found ==="
grep -r "password\|secret\|key" terraform/*.tfvars 2>/dev/null || echo "No tfvars files"
grep -r "password" ansible/*.yml 2>/dev/null | grep -v "^#" || echo "No passwords in Ansible"

# Check git protection
echo -e "\n=== Git Protection ==="
git ls-files | grep -E "\.tfvars$|secret|password" && echo "⚠️  SECRETS IN GIT!" || echo "✅ Clean"

# Check SSH key usage
echo -e "\n=== SSH Keys ==="
ls ~/.ssh/*.pub 2>/dev/null && echo "✅ SSH keys exist" || echo "❌ No SSH keys"

# Check FileVault
echo -e "\n=== Disk Encryption ==="
fdesetup status
```

## 🆘 Emergency: If Secrets Leak

### If git leaked secrets:

```bash
# 1. Change ALL passwords immediately
ssh root@192.168.2.50
passwd  # Change root password

# Change all VM passwords
ssh root@192.168.2.202
passwd

ssh dincer@192.168.2.10
passwd

# 2. Regenerate API tokens
pveum user token remove root@pam terraform
pveum user token add root@pam terraform --privsep 0

# 3. Clean git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch terraform/terraform.tfvars" \
  --prune-empty --tag-name-filter cat -- --all

# 4. Force push (if necessary)
git push --force --all

# 5. Update all credentials in Keychain
security delete-generic-password -a "$(whoami)" -s "proxmox-password"
security add-generic-password -a "$(whoami)" -s "proxmox-password" -w "NEW_PASSWORD"
```

## 📚 Resources

- [SSH Key Tutorial](https://www.ssh.com/academy/ssh/keygen)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [1Password CLI](https://developer.1password.com/docs/cli)
- [Git Secrets](https://github.com/awslabs/git-secrets)
- [macOS Keychain](https://support.apple.com/guide/keychain-access)

## 💡 Pro Tips

1. **Use different passwords** for each service
2. **Rotate passwords** every 6-12 months
3. **Enable 2FA** on Proxmox web UI
4. **Backup** your SSH keys (encrypted backup!)
5. **Document** where secrets are stored

---

**Ready to improve your security? Let's start with SSH keys!** 🔐
