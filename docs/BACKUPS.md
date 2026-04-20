# Backups

## Strategy

| What | Method | Destination | Schedule |
|------|--------|-------------|----------|
| All VMs (vzdump) | Proxmox vzdump snapshots | USB drive (`/mnt/usb-backup`) | Weekly (Ansible) |
| Immich DB | pg_dump via Ansible | USB drive | Weekly |
| Immich photos | rsync via Ansible | USB drive | Weekly |
| Home Assistant | HAOS built-in backup | HAOS internal | Daily (auto) |

## Ansible Playbooks

| Playbook | What it backs up |
|----------|-----------------|
| `backup.yml` | Runs all backup playbooks below |
| `backup-vzdump.yml` | Full VM snapshots for all VMs |
| `backup-immich-db.yml` | PostgreSQL dump from Immich VM |
| `backup-photos.yml` | rsync Immich photo library |
| `backup-homeassistant.yml` | Trigger HAOS backup API |
| `backup-usb-setup.yml` | Mount/format USB drive |

## Running Backups

```bash
# Full backup (all VMs + Immich + HAOS)
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/backup.yml

# Single target
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/backup-immich-db.yml
```

## Verification

```bash
# Check USB mount
ssh root@10.10.10.1 "ls /mnt/usb-backup/"

# Check vzdump sizes
ssh root@10.10.10.1 "ls -lh /mnt/usb-backup/dump/"
```
