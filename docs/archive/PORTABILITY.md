# Portability Analysis & Setup

## Current State: Partially Portable

### ✅ What's Portable (In Git)
- Infrastructure code (Terraform)
- Configuration management (Ansible)
- Documentation
- Scripts

### ❌ What's NOT Portable (Machine-Specific)
1. **macOS Keychain** - Only on this Mac
2. **SSH Keys** - `~/.ssh/homeserver_ed25519` (local only)
3. **Terraform/Ansible** - Need manual installation
4. **Environment variables** - `~/.zshrc` (local only)
5. **Ansible vault password** - `.vault_pass` (gitignored, local only)

### Current Setup Time on New Machine
**~30-45 minutes** of manual configuration

---

## Solutions for Full Portability

### Option 1: Quick Setup Script (15 minutes) ⭐ RECOMMENDED

**What:** Automated script that sets up everything
**Time to new machine:** ~5 minutes

```bash
# On new machine:
git clone https://github.com/halitdincer/homeserver-iac.git
cd homeserver-iac
./quick-setup.sh

# Script will:
# 1. Install Terraform & Ansible
# 2. Prompt for secrets (or load from 1Password)
# 3. Set up SSH keys
# 4. Configure environment
# 5. Test connectivity
```

**Pros:**
- ✅ Fast setup
- ✅ Works on any Mac/Linux
- ✅ Minimal dependencies

**Cons:**
- Still need to provide secrets manually
- SSH keys need to be copied from old machine

---

### Option 2: 1Password + Setup Script (10 minutes) ⭐⭐ BEST

**What:** Store all secrets in 1Password, sync automatically
**Time to new machine:** ~3 minutes

```bash
# On new machine:
git clone https://github.com/halitdincer/homeserver-iac.git
cd homeserver-iac
./setup-with-1password.sh

# Script will:
# 1. Install Terraform, Ansible, 1Password CLI
# 2. Pull all secrets from 1Password
# 3. Configure everything automatically
# 4. You're ready!
```

**What goes in 1Password:**
- Proxmox password
- SSH private key
- Ansible vault password
- Any other credentials

**Pros:**
- ✅ Fully automated
- ✅ Secrets sync across all devices
- ✅ Most secure
- ✅ Professional solution

**Cons:**
- Requires 1Password subscription ($5/month)

---

### Option 3: Dotfiles Repository (20 minutes)

**What:** Separate repo for SSH keys and configs
**Time to new machine:** ~10 minutes

```bash
# Private dotfiles repo contains:
~/.ssh/homeserver_ed25519
~/.ssh/config
~/.zshrc (homeserver exports)
```

```bash
# On new machine:
git clone https://github.com/halitdincer/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh  # Symlinks everything

git clone https://github.com/halitdincer/homeserver-iac.git
cd homeserver-iac
./quick-setup.sh
```

**Pros:**
- ✅ Standard practice
- ✅ Works for all your configs
- ✅ Version controlled

**Cons:**
- Need to manage two repos
- SSH keys in git (encrypted hopefully)

---

### Option 4: Docker Container (30 minutes) 🐳

**What:** Complete environment in Docker
**Time to new machine:** ~2 minutes

```bash
# On new machine (only needs Docker):
docker run -it halitdincer/homeserver-iac

# Inside container, everything is ready:
terraform plan
ansible all -m ping
```

**Pros:**
- ✅ Identical environment everywhere
- ✅ No local installation needed
- ✅ Works on Mac, Linux, Windows

**Cons:**
- Container setup complexity
- Secrets still need to be injected

---

### Option 5: GitHub Codespaces (5 minutes) ☁️

**What:** Cloud development environment
**Time to new machine:** Instant (runs in browser)

```bash
# Just click "Open in Codespaces" on GitHub
# Pre-configured with:
# - Terraform
# - Ansible
# - All tools
# - Secrets from GitHub Secrets
```

**Pros:**
- ✅ Zero local setup
- ✅ Access from any device (even iPad!)
- ✅ Consistent environment

**Cons:**
- Requires GitHub Codespaces (free tier limited)
- Internet required

---

## Recommended Setup for You

### Phase 1: Quick Win (Today - 15 min)

**Create automated setup script:**

```bash
~/homeserver-iac/quick-setup.sh
```

This handles tool installation and basic config.

### Phase 2: Full Automation (This Week - 30 min)

**Option A: If you have 1Password**
- Store secrets in 1Password
- Create 1Password integration script
- Full automation achieved

**Option B: If you don't want to pay**
- Create encrypted dotfiles repo
- Store SSH keys and configs
- Semi-automated setup

### Phase 3: Ultimate Portability (Optional)

**Add GitHub Codespaces support**
- Create `.devcontainer/devcontainer.json`
- One-click cloud access
- Manage from anywhere

---

## Detailed Implementation

### Quick Setup Script

Creates a script that:
1. Detects OS (macOS, Linux)
2. Installs Terraform & Ansible
3. Prompts for secrets
4. Configures environment
5. Tests connectivity

### 1Password Integration

Stores in 1Password:
```
Homelab/Proxmox/password
Homelab/Proxmox/ssh-key
Homelab/Proxmox/vault-password
```

Retrieves with:
```bash
export TF_VAR_proxmox_password=$(op read "op://Homelab/Proxmox/password")
```

### Dotfiles Repository

Structure:
```
~/.dotfiles/
├── ssh/
│   ├── homeserver_ed25519
│   └── config
├── shell/
│   └── homeserver.sh
└── install.sh
```

---

## What You Need to Decide

1. **Budget:** Free or $5/month for 1Password?
2. **Complexity:** Simple script or full automation?
3. **Security:** Encrypted dotfiles or 1Password?

---

## My Recommendation

**For your use case (portable Claude management):**

1. **Now:** Create quick-setup.sh script (15 min)
2. **Soon:** Add 1Password integration (30 min)
3. **Later:** Add Codespaces support (optional)

This gives you:
- ✅ 3-minute setup on any machine
- ✅ All secrets synced automatically
- ✅ Optional cloud access
- ✅ Professional workflow

---

## Current Portability Score

**Before:** 2/10 (Requires full manual setup)
**With Quick Script:** 6/10 (Semi-automated)
**With 1Password:** 9/10 (Fully automated)
**With Codespaces:** 10/10 (Zero-setup cloud access)

---

**Want me to implement any of these?**
