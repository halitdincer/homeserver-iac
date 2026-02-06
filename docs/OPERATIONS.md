# Common Operations

Frequently used operations for managing your homeserver infrastructure.

## VM Management

### Modify VM Resources

#### Add RAM

```bash
cd ~/homeserver-iac/terraform

# Edit vms.tf
# Change: memory = 16384
# To:     memory = 20480

terraform plan   # Review changes
terraform apply  # Apply changes

# Restart VM for change to take effect
ssh root@192.168.2.50 "qm shutdown 100 && qm start 100"
```

#### Add CPU Cores

```bash
# Edit vms.tf
# Change: cores = 4
# To:     cores = 6

terraform apply

# Hot-plug (no restart needed if guest agent is running)
# Change takes effect immediately
```

#### Expand Disk

```bash
# Edit vms.tf
# Change: size = "64G"
# To:     size = "128G"

terraform apply

# Resize partition inside VM
ssh root@192.168.2.202
lsblk
growpart /dev/sda 1
resize2fs /dev/sda1
```

### Create New VM

```bash
# Add to terraform/vms.tf

resource "proxmox_vm_qemu" "new_service" {
  name   = "new-service"
  vmid   = 104  # Next available ID
  cores  = 2
  memory = 4096

  # ... copy structure from existing VM
}

terraform plan
terraform apply

# Configure with Ansible
ansible-playbook ansible/playbooks/new-service.yml
```

### Delete VM

```bash
# Remove from terraform/vms.tf
# Or comment out the resource block

terraform plan   # Verify what will be deleted
terraform apply

# Terraform will:
# 1. Stop the VM
# 2. Delete the VM
# 3. Remove from state
```

## Service Configuration

### Update Service with Ansible

```bash
cd ~/homeserver-iac/ansible

# Edit playbook
nano playbooks/immich.yml

# Apply changes
ansible-playbook -i inventory/hosts.yml playbooks/immich.yml

# Or run specific tags
ansible-playbook -i inventory/hosts.yml playbooks/immich.yml --tags docker
```

### Restart Service

```bash
# Via Ansible
ansible nginx -i inventory/hosts.yml -m shell -a "docker restart nginx-proxy-manager"

# Or directly
ssh dincer@192.168.2.10
docker restart nginx-proxy-manager
```

### View Service Logs

```bash
# Via Ansible
ansible immich -i inventory/hosts.yml -m shell -a "docker logs immich_server -n 100"

# Or directly
ssh root@192.168.2.202
docker logs -f immich_server
```

## Backup & Restore

### Backup Terraform State

```bash
cd ~/homeserver-iac/terraform

# Create backup
cp terraform.tfstate terraform.tfstate.backup-$(date +%Y%m%d)

# Or use remote backend (recommended)
# See: https://www.terraform.io/docs/language/settings/backends/
```

### Backup VM in Proxmox

```bash
# Via Proxmox CLI
ssh root@192.168.2.50

# Backup VM 100
vzdump 100 --mode snapshot --compress zstd --storage local

# List backups
ls -lh /var/lib/vz/dump/

# Restore from backup
qmrestore /var/lib/vz/dump/vzdump-qemu-100-*.vma.zst 100
```

### Export Configuration

```bash
# Export current VM configs
cd ~/homeserver-iac
mkdir -p backups

ssh root@192.168.2.50 "qm config 100" > backups/vm-100-config.txt
ssh root@192.168.2.50 "qm config 102" > backups/vm-102-config.txt
ssh root@192.168.2.50 "qm config 103" > backups/vm-103-config.txt

git add backups/
git commit -m "Backup VM configurations"
```

## Network Changes

### Change VM IP Address

```bash
# 1. Update Ansible inventory
nano ansible/inventory/hosts.yml
# Change ansible_host IP

# 2. Update inside VM
ssh root@192.168.2.202
nano /etc/netplan/00-installer-config.yaml
# Update IP address
netplan apply

# 3. Update Nginx Proxy Manager
# Update proxy host to point to new IP

# 4. Update documentation
nano docs/CURRENT_STATE.md
```

### Add New Network Interface

```bash
# Edit terraform/vms.tf
# Add another network block:

  network {
    model  = "virtio"
    bridge = "vmbr1"  # Second bridge
  }

terraform apply

# Configure inside VM
ssh root@192.168.2.202
ip link show
```

## Monitoring

### Check All VM Status

```bash
# Via Terraform
cd ~/homeserver-iac/terraform
terraform show | grep -A5 "resource.*qemu"

# Via Proxmox
ssh root@192.168.2.50 "qm list"

# Via Ansible
ansible all -i ansible/inventory/hosts.yml -m ping
```

### Check Resource Usage

```bash
ssh root@192.168.2.50

# All VMs
pvesh get /cluster/resources --type vm --output-format json | jq

# Specific VM
qm status 100
qm monitor 100
```

### Check Service Health

```bash
# All services
ansible all -i ansible/inventory/hosts.yml -m shell -a "systemctl status docker"

# Specific service
ansible nginx -i ansible/inventory/hosts.yml -m shell -a "docker ps"
```

## Updates

### Update Terraform Provider

```bash
cd ~/homeserver-iac/terraform

# Update provider version in main.tf
# Change: version = "~> 3.0"
# To:     version = "~> 3.1"

terraform init -upgrade
terraform plan
```

### Update Docker Containers

```bash
# Via Ansible
ansible immich -i ansible/inventory/hosts.yml -m shell -a "cd /opt/immich && docker-compose pull && docker-compose up -d"

# Or directly
ssh root@192.168.2.202
cd /opt/immich
docker-compose pull
docker-compose up -d
```

### Update Proxmox VE

```bash
ssh root@192.168.2.50

# Update packages
apt update
apt dist-upgrade

# Reboot if kernel updated
reboot
```

## Troubleshooting

### Terraform State Issues

```bash
# Check state
terraform show

# Refresh state from actual infrastructure
terraform refresh

# Remove resource from state (doesn't delete VM)
terraform state rm proxmox_vm_qemu.immich

# Re-import
terraform import proxmox_vm_qemu.immich pve1/qemu/100

# List state resources
terraform state list
```

### Ansible Connection Issues

```bash
# Test connection
ansible all -i ansible/inventory/hosts.yml -m ping -vvv

# Check SSH
ssh -v root@192.168.2.202

# Reset SSH keys
ssh-keygen -R 192.168.2.202
```

### VM Won't Start

```bash
ssh root@192.168.2.50

# Check VM status
qm status 100

# Check errors
qm start 100

# View logs
journalctl -u pve-cluster -n 100

# Check locks
qm unlock 100
```

### Service Not Responding

```bash
# Check if running
ssh root@192.168.2.202 "docker ps"

# Check logs
ssh root@192.168.2.202 "docker logs immich_server -n 100"

# Restart
ssh root@192.168.2.202 "docker restart immich_server"

# Full reset
ssh root@192.168.2.202 "cd /opt/immich && docker-compose down && docker-compose up -d"
```

## Git Workflow

### Commit Changes

```bash
cd ~/homeserver-iac

# Check what changed
git status
git diff

# Stage changes
git add terraform/vms.tf
git add ansible/playbooks/

# Commit
git commit -m "Add 2GB RAM to Immich VM"

# Push
git push
```

### Rollback Changes

```bash
# View history
git log --oneline

# Revert to previous commit
git revert HEAD

# Or reset (destructive!)
git reset --hard HEAD~1

# Re-apply with Terraform
terraform plan
terraform apply
```

### Work with Branches

```bash
# Create branch for testing
git checkout -b test-jellyfin

# Make changes
# ...

# Test
terraform plan

# If good, merge
git checkout main
git merge test-jellyfin

# If bad, delete
git checkout main
git branch -D test-jellyfin
```

## Performance Tuning

### Enable CPU Flags

```bash
# Edit vms.tf
# Change: cpu = "host"
# To:     cpu = "host,flags=+aes"

terraform apply
```

### Optimize Disk I/O

```bash
# Edit vms.tf for disk settings
# Add: cache = "writeback"
# Add: ssd = 1

terraform apply
```

### Adjust QEMU Agent

```bash
# Ensure agent is installed in VM
ssh root@192.168.2.202
apt install qemu-guest-agent
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent

# Enable in Terraform (already set)
# agent = 1
```

## Maintenance Tasks

### Monthly Checklist

- [ ] Check VM disk usage
- [ ] Review Proxmox updates
- [ ] Check backup status
- [ ] Update Docker containers
- [ ] Review security updates
- [ ] Check Terraform state consistency
- [ ] Verify all services are running
- [ ] Review logs for errors

### Commands

```bash
# Disk usage
ansible all -i ansible/inventory/hosts.yml -m shell -a "df -h"

# Check updates
ssh root@192.168.2.50 "apt update && apt list --upgradable"

# Container updates
ansible all -i ansible/inventory/hosts.yml -m shell -a "docker images | grep -v REPOSITORY | awk '{print \$1\":\"\$2}' | xargs -L1 docker pull"

# Service status
ansible all -i ansible/inventory/hosts.yml -m shell -a "systemctl status docker"
```

## Quick Reference

```bash
# Terraform
terraform init              # Initialize
terraform plan              # Preview changes
terraform apply             # Apply changes
terraform destroy           # Destroy infrastructure
terraform show              # Show current state
terraform state list        # List resources

# Ansible
ansible-playbook playbook.yml           # Run playbook
ansible-playbook playbook.yml --check   # Dry run
ansible all -m ping                     # Test connectivity
ansible all -m shell -a "command"       # Run command

# Proxmox
qm list                     # List VMs
qm status <vmid>           # VM status
qm start <vmid>            # Start VM
qm stop <vmid>             # Stop VM
qm shutdown <vmid>         # Graceful shutdown
qm config <vmid>           # Show config
```
