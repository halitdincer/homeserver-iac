# Tailscale Setup Complete! 🎉

## Your Tailscale Network

| Device | Tailscale IP | Local IP | Purpose |
|--------|--------------|----------|---------|
| Your Mac (halits-macbook-air) | `100.89.218.49` | N/A | Remote management client |
| Proxmox (pve1) | `100.117.57.21` | 192.168.2.50 | Remote server management |
| Nginx Proxy Manager | `100.119.146.124` | 192.168.2.10 | Remote admin interface access |

## Architecture

**Management Access (Via Tailscale - Private):**
- Proxmox Web UI: `https://100.117.57.21:8006`
- Nginx Admin UI: `http://100.119.146.124:81`
- SSH to Proxmox: `ssh root@100.117.57.21`
- SSH to Nginx: (access via Tailscale IP)

**Public Services (Via Nginx - Public Internet):**
- ✅ Immich: https://photos.halitdincer.com (stays public)
- ✅ Home Assistant: https://ha.halitdincer.com (stays public)
- ✅ Nginx Proxy Manager: https://nginx.halitdincer.com (stays public)

**Important:** Immich and Home Assistant VMs do NOT have Tailscale installed. They remain publicly accessible only through Nginx Proxy Manager.

## Quick Access

### SSH to Proxmox via Tailscale (works from anywhere!)
```bash
ssh root@100.117.57.21
```

### Access Proxmox Web UI via Tailscale
```bash
# Open in browser:
https://100.117.57.21:8006
```

### Check Tailscale Status
```bash
tailscale status
```

### Your Tailscale IPs
```bash
tailscale ip -4
```

## Using Terraform Remotely

### At Home (Local Network)
```bash
cd ~/homeserver-iac/terraform
terraform plan   # Uses 192.168.2.50
```

### Away from Home (Via Tailscale)
```bash
cd ~/homeserver-iac/terraform
export TF_VAR_proxmox_api_url="https://100.117.57.21:8006/api2/json"
terraform plan   # Uses Tailscale IP!
```

### Or edit terraform.tfvars temporarily:
```hcl
# For remote access, change:
proxmox_api_url = "https://192.168.2.50:8006/api2/json"
# To:
proxmox_api_url = "https://100.117.57.21:8006/api2/json"
```

## What You Can Do Now

✅ **Manage Proxmox from anywhere** (coffee shop, vacation, etc.)
✅ **SSH to your homeserver** from any network
✅ **Run Terraform/Ansible** remotely
✅ **Access Proxmox Web UI** securely from anywhere
✅ **No port forwarding needed** - completely secure

## Why Only Nginx Has Tailscale (Not Immich/Home Assistant)

**Nginx Proxy Manager:**
- ✅ Has Tailscale for remote admin access
- ✅ Still serves public websites (Immich, Home Assistant, etc.)
- You can manage Nginx remotely via Tailscale, while public services stay public

**Immich & Home Assistant:**
- ❌ Do NOT have Tailscale
- ✅ Accessible publicly via their domains only
- This keeps them isolated and simple

**Access Pattern:**
```
Public Internet → Nginx (192.168.2.10) → Immich/Home Assistant
     You (Remote) → Tailscale → Nginx Admin (100.119.146.124:81)
     You (Remote) → Tailscale → Proxmox (100.117.57.21:8006)
```

## Tailscale Admin Console

Manage your devices: https://login.tailscale.com/admin/machines

- Add/remove devices
- Share access with others
- Configure access controls
- View connection logs

## Testing Connectivity

```bash
# Ping Proxmox via Tailscale
ping 100.117.57.21

# SSH to Proxmox via Tailscale
ssh root@100.117.57.21

# Check what's accessible
tailscale status
```

## Troubleshooting

### If Tailscale disconnects
```bash
# On Mac:
tailscale up

# On Proxmox:
ssh root@192.168.2.50  # Use local IP first
tailscale up
```

### Check Tailscale is running
```bash
# On Mac:
tailscale status

# On Proxmox:
ssh root@192.168.2.50 "systemctl status tailscaled"
```

## Next Steps

1. ✅ Tailscale installed on Mac - DONE
2. ✅ Tailscale installed on Proxmox - DONE
3. ✅ Connectivity tested - DONE
4. 🔄 (Optional) Install on VMs for direct access
5. 🔄 (Optional) Create alias/script for easy remote Terraform

## Creating Easy Remote Access

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Homeserver management aliases
alias homeserver-local='cd ~/homeserver-iac && unset TF_VAR_proxmox_api_url'
alias homeserver-remote='cd ~/homeserver-iac && export TF_VAR_proxmox_api_url="https://100.117.57.21:8006/api2/json"'

# Quick Proxmox access
alias proxmox-local='ssh root@192.168.2.50'
alias proxmox-remote='ssh root@100.117.57.21'
alias proxmox='ssh root@100.117.57.21'  # Always use Tailscale
```

Then reload:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

Now you can just type:
```bash
homeserver-remote
terraform plan  # Works from anywhere! ☕
```

---

**You now have secure, remote access to your homeserver from anywhere in the world!** 🌍
