# Security & Secrets Management

## 🔒 Current Secret Protection

### ✅ What's Protected (NOT in Git)

| File | Contains | Status |
|------|----------|--------|
| `terraform/terraform.tfvars` | Proxmox password | ✅ Protected by .gitignore |
| `terraform/terraform.tfstate` | VM IPs, configs, sensitive data | ✅ Protected by .gitignore |
| `terraform/.terraform/` | Provider cache | ✅ Protected by .gitignore |
| `ansible/inventory/hosts.yml` | Currently IN GIT ⚠️ | Contains IP addresses |

### ✅ What's Safe to Commit (IN Git)

| File | Contains | Safe? |
|------|----------|-------|
| `terraform/*.tf` | Infrastructure definitions | ✅ Yes - no secrets |
| `terraform/terraform.tfvars.example` | Template with placeholders | ✅ Yes - example only |
| `ansible/playbooks/*.yml` | Service configurations | ✅ Yes - no credentials |
| All documentation | Guides and instructions | ✅ Yes |

## 🔐 Secrets in Your Setup

### 1. Proxmox Credentials
**Location:** `terraform/terraform.tfvars`
```hcl
proxmox_password = "<REDACTED>"  # ⚠️ NEVER commit this file!
```

**Protection:**
- ✅ Blocked by `.gitignore` entry: `*.tfvars`
- ✅ Not in GitHub repository
- ✅ Only exists locally on your machine

### 2. Nginx VM Password
**Location:** `~/.claude/CLAUDE.md` (global Claude config)
```
SSH to Nginx VM: ssh dincer@192.168.2.10 (password: <REDACTED>)
```

**Protection:**
- ✅ NOT in the homeserver-iac repository
- ✅ Only in your local Claude configuration
- ⚠️ Consider using SSH keys instead of password

### 3. Terraform State File
**Location:** `terraform/terraform.tfstate`

**Contains:**
- VM MAC addresses
- IP addresses (192.168.2.x)
- Disk configurations
- Resource IDs

**Protection:**
- ✅ Blocked by `.gitignore` entry: `*.tfstate*`
- ✅ Not in GitHub repository
- ✅ Local backend only

## ⚠️ Current Vulnerabilities

### 1. Ansible Inventory Contains IPs
**File:** `ansible/inventory/hosts.yml`
**Status:** Currently IN git repository

**Contains:**
```yaml
immich:
  ansible_host: 192.168.2.202
nginx:
  ansible_host: 192.168.2.10
  ansible_user: dincer
```

**Risk Level:** Low (internal IPs only)
**Recommendation:** Keep it - internal IPs are not sensitive

### 2. Passwords in Plain Text
**Location:** `terraform/terraform.tfvars`

**Current:**
```hcl
proxmox_password = "<REDACTED>"
```

**Risk:** If file is accidentally committed or machine is compromised

**Mitigation:**
- ✅ Protected by .gitignore
- Consider: Environment variables or Ansible Vault

## 🛡️ Security Best Practices (Current)

### ✅ What We're Doing Right

1. **Gitignore Protection**
   - All secret files blocked
   - State files excluded
   - Credentials never committed

2. **Private Repository**
   - Repository is private on GitHub
   - Only you have access
   - Even if secrets leaked, repo is private

3. **Template Files**
   - `.example` files show structure
   - No real credentials in examples
   - Easy for others to replicate setup

4. **Documentation**
   - Clear security guidelines
   - Warnings about sensitive files
   - Regular reminders in docs

## 🚀 Recommended Improvements

### 1. Use Environment Variables (Easy)

**Instead of:**
```hcl
# terraform.tfvars
proxmox_password = "<REDACTED>"
```

**Use:**
```bash
# In your shell
export TF_VAR_proxmox_password="<REDACTED>"

# terraform.tfvars becomes optional
# Password only in memory, not on disk
```

**Pros:**
- Password not stored in file
- More secure
- Still gitignored via shell profile

**Cons:**
- Need to set every time
- Claude needs you to provide it

### 2. Use Ansible Vault (Medium)

**For Ansible secrets:**
```bash
# Create encrypted file
ansible-vault create ansible/secrets.yml

# Use in playbooks
vars_files:
  - secrets.yml
```

**Pros:**
- Encrypted secrets can be committed
- Password protected
- Industry standard

**Cons:**
- Need to remember vault password
- More complex workflow

### 3. Use External Secret Management (Advanced)

**Options:**
- **1Password CLI** - `op read op://vault/item/password`
- **AWS Secrets Manager** - For cloud deployments
- **HashiCorp Vault** - Enterprise solution

**Pros:**
- Centralized secrets
- Audit logs
- Rotation support

**Cons:**
- Complex setup
- Overkill for homelab

### 4. SSH Keys Instead of Passwords

**Current:** `ssh dincer@192.168.2.10` (password: <REDACTED>)

**Better:**
```bash
ssh-copy-id dincer@192.168.2.10
# Now passwordless login
```

**Pros:**
- No password in files
- More secure
- Required for Ansible automation

## 🔍 Audit Your Security

### Check for Leaked Secrets

```bash
cd ~/homeserver-iac

# Check what's in git
git ls-files | xargs grep -l "<REDACTED>" && echo "⚠️ PASSWORD FOUND!" || echo "✅ Clean"

# Check for any .tfvars in git
git ls-files | grep "\.tfvars$" && echo "⚠️ TFVARS IN GIT!" || echo "✅ Clean"

# List all tracked files
git ls-files
```

### Verify .gitignore is Working

```bash
cd ~/homeserver-iac/terraform

# Try to add secrets (should fail)
git add terraform.tfvars
# Output: "The following paths are ignored by one of your .gitignore files"
```

## 📋 Security Checklist

- [x] `terraform.tfvars` is gitignored
- [x] `terraform.tfstate` is gitignored
- [x] Repository is private
- [x] No passwords in committed files
- [x] Documentation warns about secrets
- [ ] Consider using environment variables
- [ ] Set up SSH keys for Ansible
- [ ] Consider Ansible Vault for future secrets
- [ ] Regular security audits

## 🆘 If Secrets Are Leaked

### If you accidentally commit secrets:

```bash
# 1. Remove from git history (if not pushed)
git reset HEAD~1
git commit --amend

# 2. If already pushed to GitHub
# IMMEDIATELY change all passwords!
# Then use BFG Repo-Cleaner or git-filter-branch

# 3. Rotate credentials
ssh root@192.168.2.50
passwd  # Change root password
pveum user token remove root@pam terraform
pveum user token add root@pam terraform --privsep 0
# Update terraform.tfvars with new token
```

### If repository becomes public:

1. **Immediately make it private again**
2. **Change ALL passwords**
3. **Regenerate API tokens**
4. **Review GitHub security alerts**

## 📚 Resources

- [Terraform Sensitive Variables](https://www.terraform.io/docs/language/values/variables.html#suppressing-values-in-cli-output)
- [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Git Secrets](https://github.com/awslabs/git-secrets)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)

## Summary

**Your secrets are currently well protected:**
- ✅ Nothing sensitive in git
- ✅ Private repository
- ✅ Proper .gitignore
- ✅ State files excluded

**For a homelab, this is excellent security.**

For production or if you're concerned about additional security, consider implementing the recommended improvements above.

---

**Questions about security? Ask Claude!** 🔒
