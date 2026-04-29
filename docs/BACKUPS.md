# Backups

## Strategy

| What | Method | Destination | Schedule |
|------|--------|-------------|----------|
| All VMs (vzdump) | Proxmox `vzdump` snapshots | USB drive (`/mnt/usb-backup/vzdump`) | Weekly (Proxmox cron — `Sun 02:00`) |
| Immich DB | `pg_dump` via Ansible | USB drive (`/mnt/usb-backup/immich-db`) | Weekly (manual) |
| Immich photos | rsync via Ansible | USB drive (`/mnt/usb-backup/immich-photos`) | Weekly (manual) |
| Home Assistant | HAOS built-in backup | HAOS internal | Daily (auto) |

## USB drive layout

The USB drive is a Crucial P3 1 TB NVMe in a Realtek RTL9210 enclosure, presented as `/dev/sda` on the Proxmox host.

- **Filesystem**: exFAT (label: `Dincer Disk`). The drive is shared with the user's personal files — do NOT reformat.
- **UUID**: `6786-E1F3`
- **fstab entry**:
  ```
  UUID=6786-E1F3 /mnt/usb-backup exfat defaults,nofail,uid=root,gid=root,umask=022,x-systemd.device-timeout=30 0 0
  ```
- **Subdirectories** (created alongside personal data, not at the root):
  - `/mnt/usb-backup/vzdump`     — Proxmox vzdump archives (registered as Proxmox storage `usb-backup`)
  - `/mnt/usb-backup/immich-db`     — Immich Postgres dumps
  - `/mnt/usb-backup/immich-photos` — Immich photo library rsync

## Proxmox storage + vzdump job

The directory `/mnt/usb-backup/vzdump` is registered as a Proxmox storage pool named `usb-backup` (content type: `backup`, `is_mountpoint=/mnt/usb-backup`).

The weekly job (`id: a6963466-fb6e-4351-b063-72b4de3f2d7b`, comment `backup-weekly-all`) runs at `Sun 02:00`, snapshot mode, zstd compressed, vmids `100,103,105`, retention `keep-last=4,keep-weekly=4`.

Inspect / modify:
```bash
ssh root@10.10.10.1 'pvesh get /cluster/backup/a6963466-fb6e-4351-b063-72b4de3f2d7b'
ssh root@10.10.10.1 'pvesh set /cluster/backup/<id> --storage usb-backup --prune-backups keep-last=4,keep-weekly=4'
```

## Ansible playbooks

| Playbook | What it does |
|----------|-----------------|
| `backup.yml` | Runs all backup playbooks below |
| `backup-vzdump.yml` | Manual full VM snapshots (cron job runs weekly automatically) |
| `backup-immich-db.yml` | PostgreSQL dump from Immich VM |
| `backup-photos.yml` | rsync Immich photo library |
| `backup-homeassistant.yml` | Trigger HAOS backup API |
| `backup-usb-setup.yml` | **DEPRECATED**: fresh-format path. Current drive is exFAT, shared with personal data. See "Re-mounting after a USB drop" below. |

## Running backups manually

```bash
# Full backup (all VMs + Immich + HAOS)
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/backup.yml

# Single target
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/backup-immich-db.yml

# One-off vzdump (e.g. before a risky upgrade)
ssh root@10.10.10.1 'vzdump 105 --storage usb-backup --mode snapshot --compress zstd'
```

## Verification

```bash
# Check USB mount
ssh root@10.10.10.1 'df -h /mnt/usb-backup && ls /mnt/usb-backup/vzdump/dump/'

# Check storage status (Proxmox)
ssh root@10.10.10.1 'pvesm status --storage usb-backup'

# List recent vzdump archives + log
ssh root@10.10.10.1 'ls -lh /mnt/usb-backup/vzdump/dump/'
```

## Re-mounting after a USB drop

The Realtek adapter occasionally drops off the bus under USB power management; the device disappears from `/dev` and the mountpoint goes stale. To recover without a reboot:

```bash
# 1. Lazy-unmount any zombie mount
ssh root@10.10.10.1 'umount -l /mnt/usb-backup 2>/dev/null; rmdir /mnt/usb-backup 2>/dev/null'

# 2. Find the USB device path
ssh root@10.10.10.1 'lsusb -t'   # locate the Realtek adapter; note its bus/port
ssh root@10.10.10.1 'ls /sys/bus/usb/devices/'

# 3. Soft-reset the port
ssh root@10.10.10.1 'echo 0 > /sys/bus/usb/devices/<bus>-<port>/authorized; sleep 2; echo 1 > /sys/bus/usb/devices/<bus>-<port>/authorized'

# 4. Re-mount
ssh root@10.10.10.1 'mkdir -p /mnt/usb-backup && mount /mnt/usb-backup'
```

If a soft reset fails, physically unplug/replug the USB cable.
