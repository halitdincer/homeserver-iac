# GitHub Codespaces Setup

This devcontainer configuration allows you to manage your homeserver from **any device** with a web browser!

## Quick Start

1. Go to https://github.com/halitdincer/homeserver-iac
2. Click **Code** → **Codespaces** → **Create codespace on main**
3. Wait ~2 minutes for setup
4. Add your secrets (one-time):
   - Go to Codespaces settings
   - Add `PROXMOX_PASSWORD` secret
   - Add `PROXMOX_API_URL` secret
5. Start managing your homeserver!

## What's Included

- ✅ Terraform (latest)
- ✅ Ansible (latest)
- ✅ Git secrets
- ✅ All environment variables pre-configured
- ✅ VS Code extensions (Terraform, Ansible)

## Usage

```bash
# In the Codespace terminal:

# Terraform
cd terraform
terraform plan
terraform apply

# Ansible
cd ansible
ansible all -m ping
ansible-playbook playbooks/nginx-proxy-manager.yml
```

## Benefits

- 🌐 Access from **any device** (laptop, tablet, even phone)
- ⚡ **Instant setup** - no local installation
- 🔄 **Consistent environment** - always the same tools
- 💰 **Free tier** - 60 hours/month for free

## Network Access

**Note:** You'll need either:
1. **Tailscale** VPN running on Proxmox (recommended)
2. **Exposed Proxmox API** via your domain
3. **GitHub Codespaces** on same network (unlikely)

For best results, set up Tailscale:
```bash
# On Proxmox:
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# In Codespace:
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# Now you can access Proxmox via Tailscale IP!
```

## Secrets Management

### GitHub Codespaces Secrets

1. Go to https://github.com/settings/codespaces
2. Click **New secret**
3. Add:
   - Name: `PROXMOX_PASSWORD`
   - Value: Your Proxmox password
4. Repeat for any other secrets

Secrets are automatically loaded as environment variables!

---

**Manage your homeserver from anywhere!** ☁️
