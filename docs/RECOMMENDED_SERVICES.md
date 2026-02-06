# 🚀 Top 10 Most Useful Homelab Services

Based on your current setup, here are the most valuable services to add.

## Your Current Stack

✅ **Immich** - Photo management
✅ **Nginx Proxy Manager** - Reverse proxy
✅ **Home Assistant** - Smart home
✅ **Proxmox** - Virtualization

---

## Top 10 Services to Add (Prioritized)

### 1. 🎬 Jellyfin - Media Server ⭐⭐⭐⭐⭐

**What:** Stream your movies, TV shows, music to any device
**Why Essential:** Your own Netflix/Spotify without subscriptions

**Use Case:**
- Store your media collection
- Stream to TV, phone, laptop
- No subscription fees
- Offline access

**Resources:**
- CPU: 2 cores (4 for transcoding)
- RAM: 4GB
- Storage: As much as you have!

**Setup:**
```yaml
# VM: 2 cores, 4GB RAM, 500GB+ disk
Services:
  - Jellyfin server (port 8096)
  - Hardware transcoding (optional)

Access: https://jellyfin.halitdincer.com
```

**Perfect For:** Movie/TV collection, music library, audiobooks

---

### 2. ☁️ Nextcloud - Self-Hosted Cloud ⭐⭐⭐⭐⭐

**What:** Your own Google Drive + Office + Calendar + Contacts
**Why Essential:** Complete cloud replacement, own your data

**Features:**
- File sync/share (like Dropbox)
- Office suite (docs, sheets, slides)
- Calendar & contacts sync
- Photo backup (works with Immich!)
- Notes, tasks, bookmarks
- Mobile apps

**Resources:**
- CPU: 2 cores
- RAM: 4GB
- Storage: 100GB+ (depends on usage)

**Setup:**
```yaml
# VM: 2 cores, 4GB RAM, 100GB disk
Services:
  - Nextcloud (port 443)
  - MariaDB database
  - Redis cache

Access: https://cloud.halitdincer.com
```

**Perfect For:** File storage, document editing, replacing Google Workspace

---

### 3. 🔒 Vaultwarden - Password Manager ⭐⭐⭐⭐⭐

**What:** Self-hosted Bitwarden (password manager)
**Why Essential:** Most important security tool

**Features:**
- Store all passwords securely
- Browser extensions
- Mobile apps
- 2FA support
- Password generator
- Secure notes

**Resources:**
- CPU: 1 core
- RAM: 512MB (very lightweight!)
- Storage: 1GB

**Setup:**
```yaml
# Can run in existing VM or LXC
Services:
  - Vaultwarden (port 8000)

Access: https://passwords.halitdincer.com
```

**Perfect For:** Never forget passwords, sync across devices

---

### 4. 🛡️ AdGuard Home - Network Ad Blocker ⭐⭐⭐⭐⭐

**What:** Block ads/trackers across your entire network
**Why Essential:** Better than browser extensions, protects all devices

**Features:**
- Network-wide ad blocking
- Malware/phishing protection
- DNS over HTTPS/TLS
- Detailed statistics
- Per-device controls

**Resources:**
- CPU: 1 core
- RAM: 512MB
- Storage: 2GB

**Setup:**
```yaml
# LXC container or small VM
Services:
  - AdGuard Home (port 80, 53)

Access: https://dns.halitdincer.com
Router: Point DNS to 192.168.2.x
```

**Perfect For:** Blocking ads on phones, smart TVs, IoT devices

---

### 5. 📊 Uptime Kuma - Monitoring ⭐⭐⭐⭐

**What:** Monitor all your services, get alerts when down
**Why Essential:** Know when something breaks before you notice

**Features:**
- Monitor HTTP(s), TCP, ping, DNS
- Beautiful dashboard
- Notifications (email, Discord, Slack, etc.)
- Status pages
- SSL certificate monitoring

**Resources:**
- CPU: 1 core
- RAM: 512MB
- Storage: 2GB

**Setup:**
```yaml
# Can run in existing VM
Services:
  - Uptime Kuma (port 3001)

Access: https://status.halitdincer.com
```

**Perfect For:** Knowing when services go down, SSL cert expiry alerts

---

### 6. 🐳 Portainer - Docker Management ⭐⭐⭐⭐

**What:** Web UI for managing Docker containers
**Why Essential:** Makes Docker management visual and easy

**Features:**
- Manage containers, images, volumes
- Deploy stacks (docker-compose)
- Terminal access to containers
- Resource monitoring
- Multi-host support

**Resources:**
- CPU: 1 core
- RAM: 512MB
- Storage: 2GB

**Setup:**
```yaml
# Install on each VM that runs Docker
Services:
  - Portainer (port 9443)

Access: https://docker.halitdincer.com
```

**Perfect For:** Managing all your Docker services visually

---

### 7. 🔐 Tailscale/WireGuard - VPN ⭐⭐⭐⭐⭐

**What:** Secure remote access to your homelab
**Why Essential:** Access everything from anywhere safely

**Tailscale (Easier):**
- Zero configuration
- Works anywhere
- Free for personal use
- Automatic routing

**WireGuard (More Control):**
- Self-hosted
- More complex setup
- Full control

**Resources:**
- Minimal (runs on Proxmox host)

**Setup:**
```bash
# Tailscale (recommended):
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# Access from anywhere!
```

**Perfect For:** Remote management, secure access while traveling

---

### 8. 📄 Paperless-ngx - Document Management ⭐⭐⭐⭐

**What:** Scan, organize, search all your documents
**Why Essential:** Go paperless, find any document instantly

**Features:**
- OCR (searchable PDFs)
- Auto-tagging
- Full-text search
- Mobile app for scanning
- Automated workflows
- Email import

**Resources:**
- CPU: 2 cores
- RAM: 2GB
- Storage: 50GB+

**Setup:**
```yaml
# VM: 2 cores, 2GB RAM, 50GB disk
Services:
  - Paperless-ngx (port 8000)
  - PostgreSQL
  - Redis

Access: https://docs.halitdincer.com
```

**Perfect For:** Bills, receipts, important documents, going paperless

---

### 9. 📈 Grafana + Prometheus - Metrics & Dashboards ⭐⭐⭐⭐

**What:** Beautiful dashboards for everything
**Why Essential:** See what's happening in your homelab

**Features:**
- Monitor server resources
- Track network usage
- Visualize metrics
- Alerts
- Beautiful dashboards

**Resources:**
- CPU: 2 cores
- RAM: 2GB
- Storage: 20GB

**Setup:**
```yaml
# VM: 2 cores, 2GB RAM, 20GB disk
Services:
  - Grafana (port 3000)
  - Prometheus (port 9090)
  - Node exporter (on each VM)

Access: https://grafana.halitdincer.com
```

**Perfect For:** Seeing server stats, network traffic, temperatures

---

### 10. 🏠 Homepage/Homarr - Dashboard ⭐⭐⭐⭐

**What:** Beautiful homepage for all your services
**Why Essential:** One place to access everything

**Features:**
- Links to all services
- Service status indicators
- Weather, calendar integration
- Bookmarks
- Search integration
- Custom widgets

**Resources:**
- CPU: 1 core
- RAM: 512MB
- Storage: 1GB

**Setup:**
```yaml
# Can run in existing VM
Services:
  - Homepage (port 3000)

Access: https://home.halitdincer.com or https://halitdincer.com
```

**Perfect For:** Your homelab landing page

---

## Priority Recommendations

### Start With These 3 (Immediate Value):

1. **Vaultwarden** - Security first!
2. **Tailscale** - Remote access
3. **Uptime Kuma** - Know when things break

**Time:** ~1 hour total
**Value:** Massive improvement in security & accessibility

### Add Next (High Value):

4. **AdGuard Home** - Better internet experience
5. **Portainer** - Easier Docker management
6. **Homepage** - Nice dashboard

**Time:** ~2 hours
**Value:** Quality of life improvements

### Later (If Needed):

7. **Jellyfin** - If you have media
8. **Nextcloud** - If you want cloud storage
9. **Paperless-ngx** - If you want to go paperless
10. **Grafana** - If you like graphs!

---

## Resource Planning

### Current Usage:
```
VM 100: Immich       - 4 CPU, 16GB RAM
VM 102: Nginx        - 2 CPU, 8GB RAM
VM 103: Home Assistant - 2 CPU, 4GB RAM
Total: 8 CPU, 28GB RAM
```

### With Top 5 Services:
```
New VM 104: Media Stack - 2 CPU, 4GB RAM
  - Vaultwarden
  - Portainer
  - Uptime Kuma
  - Homepage

New LXC 200: AdGuard Home - 1 CPU, 512MB RAM

Proxmox Host: Tailscale - minimal

Total New: 3 CPU, 4.5GB RAM
Grand Total: 11 CPU, 32.5GB RAM
```

**Your server:** Intel i5-6500T (4 cores), 16GB RAM
**Verdict:** ⚠️ At capacity with current allocations, but VMs are over-provisioned. Can add services to existing VMs.

**Recommendation:**
- Install lightweight services in VM 102 (Nginx) which has capacity
- Use LXC containers for new services (more efficient)

---

## Quick Setup Commands

### Create New VM for Services

```bash
# Using Claude/Terraform:
"Create a new VM (104) for self-hosted services with 2 cores, 4GB RAM, 32GB disk"

# Manual:
qm create 104 --name services --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0
```

### Install Vaultwarden (Quick)

```bash
# On any VM with Docker:
docker run -d --name vaultwarden \
  -v /opt/vaultwarden:/data \
  -p 8000:80 \
  --restart unless-stopped \
  vaultwarden/server:latest

# Add to Nginx Proxy Manager:
# passwords.halitdincer.com → 192.168.2.x:8000
```

### Install Tailscale (Quickest)

```bash
# On Proxmox host:
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# Done! Access from anywhere via Tailscale IP
```

---

## Service Comparison Matrix

| Service | Difficulty | Value | Resources | Must-Have? |
|---------|-----------|-------|-----------|------------|
| Vaultwarden | Easy | ⭐⭐⭐⭐⭐ | Low | YES |
| Tailscale | Easy | ⭐⭐⭐⭐⭐ | Minimal | YES |
| AdGuard Home | Easy | ⭐⭐⭐⭐⭐ | Low | YES |
| Uptime Kuma | Easy | ⭐⭐⭐⭐ | Low | YES |
| Portainer | Easy | ⭐⭐⭐⭐ | Low | Recommended |
| Homepage | Easy | ⭐⭐⭐⭐ | Low | Recommended |
| Jellyfin | Medium | ⭐⭐⭐⭐⭐ | High | If media |
| Nextcloud | Hard | ⭐⭐⭐⭐⭐ | Medium | If cloud needed |
| Paperless | Medium | ⭐⭐⭐⭐ | Medium | If paperless goal |
| Grafana | Medium | ⭐⭐⭐ | Medium | Nice to have |

---

## Bonus Services (Honorable Mentions)

11. **Gitea** - Self-hosted Git (like GitHub)
12. **Transmission/qBittorrent** - Torrent client
13. **Syncthing** - File sync between devices
14. **Calibre-Web** - E-book library
15. **PhotoPrism** - Alternative to Immich
16. **FreshRSS** - RSS feed reader
17. **Mealie** - Recipe manager
18. **Tandoor** - Recipe organizer
19. **Bookstack** - Documentation wiki
20. **Miniflux** - Minimal RSS reader

---

## My Specific Recommendations for YOU

Based on your setup and needs:

### Phase 1 (This Week - Essential Security)
1. **Vaultwarden** - Password security
2. **Tailscale** - Remote access
3. **Uptime Kuma** - Monitoring

### Phase 2 (Next Week - Quality of Life)
4. **AdGuard Home** - Ad blocking
5. **Portainer** - Docker management
6. **Homepage** - Nice dashboard

### Phase 3 (Later - If Needed)
7. **Jellyfin** - Only if you have media collection
8. **Nextcloud** - Only if you need cloud storage
9. **Paperless** - Only if going paperless
10. **Grafana** - Only if you love metrics

---

## Want Me to Install Any?

Just say:
- "Install Vaultwarden"
- "Set up Tailscale"
- "Add Jellyfin for media"

I'll:
1. Create the VM/LXC if needed
2. Write Terraform config
3. Create Ansible playbook
4. Set up Nginx proxy
5. Add SSL certificate
6. Document everything

**Which services interest you most?** 🚀
