# Troubleshooting Guide

Common issues and their solutions.

## Terraform Issues

### "Error: VM already exists"

**Problem:** Trying to create a VM that already exists in Proxmox.

**Solution:**
```bash
# Import the existing VM into Terraform state
terraform import proxmox_vm_qemu.<name> pve1/qemu/<vmid>

# Example:
terraform import proxmox_vm_qemu.immich pve1/qemu/100
```

### "Certificate verification failed"

**Problem:** Proxmox uses self-signed SSL certificate.

**Solution:**
```bash
# In terraform.tfvars, add:
pm_tls_insecure = true

# Or install proper SSL cert on Proxmox
```

### "Unauthorized" or "Authentication failed"

**Problem:** API token is incorrect or expired.

**Solution:**
```bash
# Check token
ssh root@192.168.2.50
pveum user token list root@pam

# Create new token if needed
pveum user token add root@pam terraform --privsep 0

# Update terraform.tfvars with new token
```

### "State lock"

**Problem:** Terraform state is locked from previous operation.

**Solution:**
```bash
# Force unlock (use carefully!)
terraform force-unlock <lock-id>

# Or delete lock file if using local backend
rm .terraform.tfstate.lock.info
```

### "Plan doesn't match reality"

**Problem:** Someone made manual changes in Proxmox UI.

**Solution:**
```bash
# See what changed
terraform plan

# Option 1: Update Terraform to match reality
terraform refresh

# Option 2: Revert Proxmox to match Terraform
terraform apply

# Option 3: Update Terraform code to match new reality
# Edit vms.tf, then:
terraform plan  # Should show no changes
```

### "Provider plugin not found"

**Problem:** Terraform providers not downloaded.

**Solution:**
```bash
terraform init
terraform init -upgrade  # If updating provider version
```

## Ansible Issues

### "Host unreachable"

**Problem:** Can't connect to VM via SSH.

**Solution:**
```bash
# Test SSH manually
ssh root@192.168.2.202
ssh dincer@192.168.2.10  # Note: Nginx uses 'dincer' user

# Check VM is running
ssh root@192.168.2.50 "qm status 100"

# Check firewall
ssh root@192.168.2.50 "iptables -L -n"

# Check inventory
cat ansible/inventory/hosts.yml
```

### "Permission denied (publickey)"

**Problem:** SSH key authentication failing.

**Solution:**
```bash
# Check SSH keys
ssh-add -l

# Copy key to VM
ssh-copy-id root@192.168.2.202

# Or use password temporarily
ansible all -i ansible/inventory/hosts.yml -m ping --ask-pass
```

### "Module not found: community.docker"

**Problem:** Ansible collection not installed.

**Solution:**
```bash
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.general
```

### "Playbook fails partway through"

**Problem:** Ansible playbook errors out.

**Solution:**
```bash
# Run with verbose output
ansible-playbook playbook.yml -vvv

# Continue from where it left off
ansible-playbook playbook.yml --start-at-task="task name"

# Skip problematic tasks
ansible-playbook playbook.yml --skip-tags=problematic
```

## Proxmox Issues

### "Can't connect to Proxmox web UI"

**Problem:** https://192.168.2.50:8006 not loading.

**Solution:**
```bash
# Check Proxmox is running
ping 192.168.2.50

# Check service
ssh root@192.168.2.50
systemctl status pveproxy
systemctl restart pveproxy

# Check firewall
iptables -L -n | grep 8006
```

### "VM won't start"

**Problem:** VM fails to start in Proxmox.

**Solution:**
```bash
ssh root@192.168.2.50

# Check VM status
qm status 100

# Try to start
qm start 100

# Check for lock
qm unlock 100

# View detailed logs
journalctl -u pve-cluster -n 100 | grep "VM 100"

# Check resource availability
free -h
df -h
```

### "Out of disk space"

**Problem:** local-lvm is full.

**Solution:**
```bash
ssh root@192.168.2.50

# Check usage
lvs
pvs
df -h

# Clean up
# Delete old backups
rm /var/lib/vz/dump/*

# Delete stopped VMs you don't need
qm destroy 101  # If you don't need the template

# Resize if you have space
lvextend -L +20G /dev/pve/data
```

### "High CPU usage"

**Problem:** Proxmox host CPU at 100%.

**Solution:**
```bash
ssh root@192.168.2.50

# Check what's using CPU
top
htop

# Check VMs
qm list

# Stop offending VM
qm stop 100

# Limit VM CPU
qm set 100 -cores 2 -cpulimit 0.5  # 50% of 2 cores
```

## Docker Issues

### "Container won't start"

**Problem:** Docker container keeps crashing.

**Solution:**
```bash
# Check logs
docker logs immich_server -n 100

# Check disk space
df -h

# Check if port is in use
netstat -tlnp | grep 2283

# Remove and recreate
docker rm -f immich_server
cd /opt/immich
docker-compose up -d
```

### "Can't pull images"

**Problem:** `docker pull` fails.

**Solution:**
```bash
# Check internet connectivity
ping 8.8.8.8
ping registry.hub.docker.com

# Check DNS
cat /etc/resolv.conf

# Manually pull
docker pull ghcr.io/immich-app/immich-server:release

# Check Docker daemon
systemctl status docker
systemctl restart docker
```

### "Volume mount failed"

**Problem:** Docker volume mount permission denied.

**Solution:**
```bash
# Check permissions
ls -la /opt/immich

# Fix ownership
chown -R root:root /opt/immich

# Check SELinux (if applicable)
sestatus
setenforce 0  # Temporarily disable
```

## Network Issues

### "Can't access service externally"

**Problem:** https://photos.halitdincer.com not working.

**Solution:**
```bash
# 1. Check DNS
nslookup photos.halitdincer.com
# Should resolve to your public IP via halitdincer.ddns.net

# 2. Check port forwarding on router
# Router (192.168.2.1) should forward 80,443 to 192.168.2.10

# 3. Check Nginx Proxy Manager
# Login to http://192.168.2.10:81
# Verify proxy host exists for photos.halitdincer.com

# 4. Check service is running
curl http://192.168.2.202:2283  # Should respond
```

### "SSL certificate issues"

**Problem:** HTTPS certificate errors.

**Solution:**
```bash
# Check certificate in NPM
# Go to http://192.168.2.10:81
# SSL Certificates tab
# Request new Let's Encrypt cert

# Check domain DNS
nslookup photos.halitdincer.com

# Check ports 80/443 are accessible from internet
# Use: https://www.yougetsignal.com/tools/open-ports/
```

### "Internal network unreachable"

**Problem:** VMs can't reach each other.

**Solution:**
```bash
# Check bridge
ssh root@192.168.2.50
brctl show

# Check VM network config
qm config 100 | grep net0

# Test connectivity between VMs
ssh root@192.168.2.202
ping 192.168.2.10

# Check firewall rules
iptables -L -n
```

## Git Issues

### "Merge conflicts"

**Problem:** Git merge conflicts in Terraform files.

**Solution:**
```bash
# View conflicts
git status

# Edit conflicted files
nano terraform/vms.tf
# Resolve <<<<<<< ======= >>>>>>> markers

# Mark as resolved
git add terraform/vms.tf
git commit

# Or abort merge
git merge --abort
```

### "Sensitive data in git"

**Problem:** Accidentally committed terraform.tfvars.

**Solution:**
```bash
# Remove from git history (if not pushed)
git rm --cached terraform/terraform.tfvars
git commit --amend

# If already pushed, use BFG or git-filter-branch
# Then rotate all secrets!

# Prevent future commits
echo "terraform.tfvars" >> .gitignore
git add .gitignore
git commit -m "Add terraform.tfvars to gitignore"
```

## Performance Issues

### "Slow VM performance"

**Problem:** VM is sluggish.

**Solution:**
```bash
# Check resource usage
ssh root@192.168.2.50 "qm status 100"

# Increase resources via Terraform
cd ~/homeserver-iac/terraform
# Edit vms.tf - increase cores/memory
terraform apply

# Enable virtio drivers
# Already enabled in config with: model = "virtio"

# Check disk I/O
iostat -x 1
```

### "Slow network"

**Problem:** Network throughput is low.

**Solution:**
```bash
# Ensure virtio network driver
# Already set in Terraform: model = "virtio"

# Test speed
ssh root@192.168.2.202
apt install iperf3
iperf3 -s

# From another machine
iperf3 -c 192.168.2.202
```

## Home Assistant Specific

### "HAOS won't update"

**Problem:** Home Assistant OS update fails.

**Solution:**
```bash
# Check from HA UI
# Settings > System > Updates

# Check supervisor logs
ssh root@192.168.2.50
qm terminal 103
# Login to HA console
ha supervisor logs
```

### "USB device not detected"

**Problem:** Zigbee coordinator not showing up.

**Solution:**
```bash
# Check USB passthrough
ssh root@192.168.2.50
qm config 103 | grep usb

# List USB devices
lsusb | grep 1a86:7523

# Verify in VM
qm terminal 103
ls /dev/ttyUSB*

# May need to restart VM
qm stop 103
qm start 103
```

## Emergency Procedures

### "Everything is broken"

**Disaster recovery steps:**

```bash
# 1. Access Proxmox
ssh root@192.168.2.50

# 2. Check what's running
qm list

# 3. Start stopped VMs
qm start 100
qm start 102
qm start 103

# 4. If Terraform state is corrupted
cd ~/homeserver-iac/terraform
mv terraform.tfstate terraform.tfstate.broken
terraform import proxmox_vm_qemu.immich pve1/qemu/100
terraform import proxmox_vm_qemu.nginx pve1/qemu/102
terraform import proxmox_vm_qemu.home_assistant pve1/qemu/103

# 5. Restore from backup
qmrestore /var/lib/vz/dump/vzdump-qemu-100-*.vma.zst 100
```

### "Lost API token"

**Solution:**
```bash
ssh root@192.168.2.50

# Delete old token
pveum user token remove root@pam terraform

# Create new one
pveum user token add root@pam terraform --privsep 0

# Update terraform.tfvars
```

### "Can't access Proxmox"

**Solution:**
```bash
# Physical access to server required
# Connect monitor and keyboard
# Login at console
# Check network: ip addr show
# Check service: systemctl status pveproxy
# Check firewall: iptables -L -n
```

## Getting Help

If you're still stuck:

1. **Check logs:**
   ```bash
   # Proxmox
   ssh root@192.168.2.50 "journalctl -xe"

   # Terraform
   TF_LOG=DEBUG terraform apply

   # Ansible
   ansible-playbook playbook.yml -vvvv
   ```

2. **Ask Claude Code:**
   - Provide error messages
   - Explain what you were trying to do
   - Share relevant configuration

3. **Community resources:**
   - Proxmox Forums: https://forum.proxmox.com/
   - Terraform Proxmox Provider: https://github.com/Telmate/terraform-provider-proxmox
   - r/Proxmox on Reddit

## Prevention

**Best practices to avoid issues:**

- ✅ Always run `terraform plan` before `apply`
- ✅ Commit changes to git regularly
- ✅ Keep backups of VMs
- ✅ Document manual changes
- ✅ Test changes on non-production VMs first
- ✅ Use version control for all config
- ✅ Keep Proxmox updated
- ✅ Monitor disk space and resources
