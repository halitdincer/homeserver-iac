#!/bin/bash
set -e

# Homeserver Infrastructure as Code Setup Script
# This script helps you set up the IaC environment

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Homeserver Infrastructure as Code Setup                ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if tools are installed
echo -e "${BLUE}[1/6] Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found${NC}"
    echo -e "${YELLOW}Install with: brew install terraform${NC}"
    exit 1
fi

if ! command -v ansible &> /dev/null; then
    echo -e "${RED}❌ Ansible not found${NC}"
    echo -e "${YELLOW}Install with: brew install ansible${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Terraform $(terraform version | head -1 | awk '{print $2}')${NC}"
echo -e "${GREEN}✓ Ansible $(ansible --version | head -1 | awk '{print $2}')${NC}"

# Check network connectivity to Proxmox
echo -e "\n${BLUE}[2/6] Checking Proxmox connectivity...${NC}"

if ping -c 1 -W 2 192.168.2.50 &> /dev/null; then
    echo -e "${GREEN}✓ Proxmox host reachable at 192.168.2.50${NC}"
else
    echo -e "${YELLOW}⚠ Cannot reach Proxmox at 192.168.2.50${NC}"
    echo -e "${YELLOW}Make sure you're on the same network${NC}"
fi

# Set up Terraform
echo -e "\n${BLUE}[3/6] Setting up Terraform...${NC}"

cd terraform

if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}Creating terraform.tfvars from example...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${RED}⚠ IMPORTANT: Edit terraform.tfvars with your API token!${NC}"
    echo -e "${YELLOW}Get token by running on Proxmox:${NC}"
    echo -e "${YELLOW}  ssh root@192.168.2.50${NC}"
    echo -e "${YELLOW}  pveum user token add root@pam terraform --privsep 0${NC}"

    read -p "Press enter when you've updated terraform.tfvars..."
fi

echo -e "${BLUE}Initializing Terraform...${NC}"
terraform init

echo -e "${GREEN}✓ Terraform initialized${NC}"

# Import existing VMs
echo -e "\n${BLUE}[4/6] Importing existing VMs into Terraform state...${NC}"

import_vm() {
    local resource=$1
    local vmid=$2

    if terraform state show "proxmox_vm_qemu.$resource" &> /dev/null; then
        echo -e "${GREEN}✓ VM $vmid ($resource) already imported${NC}"
    else
        echo -e "${YELLOW}Importing VM $vmid ($resource)...${NC}"
        if terraform import "proxmox_vm_qemu.$resource" "pve1/qemu/$vmid"; then
            echo -e "${GREEN}✓ Successfully imported VM $vmid${NC}"
        else
            echo -e "${RED}❌ Failed to import VM $vmid${NC}"
            echo -e "${YELLOW}This might be due to incorrect API credentials${NC}"
        fi
    fi
}

import_vm "immich" 100
import_vm "nginx" 102
import_vm "home_assistant" 103
import_vm "clone_template" 101

# Verify configuration
echo -e "\n${BLUE}[5/6] Verifying configuration...${NC}"

if terraform plan -detailed-exitcode &> /dev/null; then
    echo -e "${GREEN}✓ Configuration matches infrastructure (no changes needed)${NC}"
else
    echo -e "${YELLOW}⚠ Configuration differs from infrastructure${NC}"
    echo -e "${YELLOW}Run 'terraform plan' to see differences${NC}"
fi

# Set up Ansible
echo -e "\n${BLUE}[6/6] Setting up Ansible...${NC}"

cd ../ansible

if [ ! -f "ansible.cfg" ]; then
    cp ansible.cfg.example ansible.cfg
    echo -e "${GREEN}✓ Created ansible.cfg${NC}"
fi

echo -e "\n${BLUE}Testing Ansible connectivity...${NC}"

# Test ping (will likely fail if SSH not set up, but that's okay)
if ansible all -i inventory/hosts.yml -m ping &> /dev/null; then
    echo -e "${GREEN}✓ Ansible can connect to all hosts${NC}"
else
    echo -e "${YELLOW}⚠ Ansible connectivity test failed${NC}"
    echo -e "${YELLOW}You may need to set up SSH keys:${NC}"
    echo -e "${YELLOW}  ssh-copy-id root@192.168.2.202  # Immich${NC}"
    echo -e "${YELLOW}  ssh-copy-id dincer@192.168.2.10  # Nginx${NC}"
fi

# Summary
echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Setup Complete! ✓                                       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}What you can do now:${NC}"
echo ""
echo -e "${GREEN}1. Check infrastructure status:${NC}"
echo "   cd ~/homeserver-iac/terraform"
echo "   terraform show"
echo ""
echo -e "${GREEN}2. Make a test change:${NC}"
echo "   # Edit vms.tf to change a VM"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo -e "${GREEN}3. Deploy services with Ansible:${NC}"
echo "   cd ~/homeserver-iac/ansible"
echo "   ansible-playbook -i inventory/hosts.yml playbooks/all.yml"
echo ""
echo -e "${GREEN}4. Read the docs:${NC}"
echo "   cat ~/homeserver-iac/QUICKSTART.md"
echo "   cat ~/homeserver-iac/docs/CLAUDE.md"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "- Set up git repository"
echo "- Configure SSH keys for Ansible"
echo "- Start making changes with Claude!"
echo ""
echo -e "${YELLOW}Need help? Just ask Claude Code!${NC}"
