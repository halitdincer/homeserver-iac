#!/bin/bash
set -e

# Homeserver Infrastructure as Code - Quick Setup
# Sets up everything needed to manage your homeserver from any machine

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Homeserver IaC - Quick Setup                            ║"
echo "║  Get up and running in ~5 minutes                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo -e "${GREEN}Detected OS: $MACHINE${NC}\n"

# Step 1: Install Dependencies
echo -e "${BLUE}[1/6] Installing dependencies...${NC}"

if [ "$MACHINE" = "Mac" ]; then
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install Terraform
    if ! command -v terraform &> /dev/null; then
        echo "Installing Terraform..."
        brew install terraform
    else
        echo -e "${GREEN}✓ Terraform already installed${NC}"
    fi

    # Install Ansible
    if ! command -v ansible &> /dev/null; then
        echo "Installing Ansible..."
        brew install ansible
    else
        echo -e "${GREEN}✓ Ansible already installed${NC}"
    fi

    # Install git-secrets
    if ! command -v git-secrets &> /dev/null; then
        echo "Installing git-secrets..."
        brew install git-secrets
    else
        echo -e "${GREEN}✓ git-secrets already installed${NC}"
    fi

elif [ "$MACHINE" = "Linux" ]; then
    # Install on Linux
    echo "Installing on Linux..."

    # Install Terraform
    if ! command -v terraform &> /dev/null; then
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    else
        echo -e "${GREEN}✓ Terraform already installed${NC}"
    fi

    # Install Ansible
    if ! command -v ansible &> /dev/null; then
        sudo apt update && sudo apt install -y ansible
    else
        echo -e "${GREEN}✓ Ansible already installed${NC}"
    fi
fi

# Step 2: Check for 1Password CLI
echo -e "\n${BLUE}[2/6] Checking for 1Password CLI...${NC}"

if command -v op &> /dev/null; then
    echo -e "${GREEN}✓ 1Password CLI found${NC}"
    USE_1PASSWORD=true

    # Check if signed in
    if op account list &> /dev/null; then
        echo -e "${GREEN}✓ Already signed into 1Password${NC}"
    else
        echo -e "${YELLOW}Please sign in to 1Password:${NC}"
        eval $(op signin)
    fi
else
    echo -e "${YELLOW}1Password CLI not found. Will use manual secret entry.${NC}"
    echo -e "${YELLOW}To install: brew install --cask 1password-cli${NC}"
    USE_1PASSWORD=false
fi

# Step 3: Configure Secrets
echo -e "\n${BLUE}[3/6] Configuring secrets...${NC}"

if [ "$USE_1PASSWORD" = true ]; then
    echo -e "${GREEN}Attempting to load from 1Password...${NC}"

    # Try to load from 1Password
    PROXMOX_PASSWORD=$(op read "op://Homelab/Proxmox/password" 2>/dev/null || echo "")

    if [ -n "$PROXMOX_PASSWORD" ]; then
        echo -e "${GREEN}✓ Loaded Proxmox password from 1Password${NC}"
    else
        echo -e "${YELLOW}No 1Password entry found. Let's create one.${NC}"
        read -sp "Enter Proxmox password: " PROXMOX_PASSWORD
        echo ""

        # Save to 1Password
        echo "$PROXMOX_PASSWORD" | op item create --category=password \
            --title="Proxmox" \
            --vault="Homelab" \
            password="$PROXMOX_PASSWORD" 2>/dev/null || echo "Couldn't save to 1Password"
    fi
else
    # Manual entry
    if [ "$MACHINE" = "Mac" ]; then
        # Check macOS Keychain
        PROXMOX_PASSWORD=$(security find-generic-password -a "$(whoami)" -s "proxmox-password" -w 2>/dev/null || echo "")

        if [ -n "$PROXMOX_PASSWORD" ]; then
            echo -e "${GREEN}✓ Loaded from macOS Keychain${NC}"
        else
            read -sp "Enter Proxmox password: " PROXMOX_PASSWORD
            echo ""

            # Save to Keychain
            security add-generic-password -a "$(whoami)" -s "proxmox-password" -w "$PROXMOX_PASSWORD" -U 2>/dev/null
            echo -e "${GREEN}✓ Saved to macOS Keychain${NC}"
        fi
    else
        # Linux - use environment variable
        read -sp "Enter Proxmox password: " PROXMOX_PASSWORD
        echo ""
    fi
fi

# Step 4: Configure SSH Keys
echo -e "\n${BLUE}[4/6] Setting up SSH keys...${NC}"

SSH_KEY="$HOME/.ssh/homeserver_ed25519"

if [ -f "$SSH_KEY" ]; then
    echo -e "${GREEN}✓ SSH key already exists${NC}"
else
    if [ "$USE_1PASSWORD" = true ]; then
        # Try to load from 1Password
        op read "op://Homelab/Proxmox/ssh-key" > "$SSH_KEY" 2>/dev/null && chmod 600 "$SSH_KEY" || {
            echo -e "${YELLOW}Generating new SSH key...${NC}"
            ssh-keygen -t ed25519 -C "homeserver-iac" -f "$SSH_KEY" -N ""

            # Save to 1Password
            op item create --category=password \
                --title="Proxmox SSH Key" \
                --vault="Homelab" \
                --tags="ssh,homeserver" 2>/dev/null || echo "Couldn't save SSH key to 1Password"
        }
    else
        echo -e "${YELLOW}Generating new SSH key...${NC}"
        ssh-keygen -t ed25519 -C "homeserver-iac" -f "$SSH_KEY" -N ""
    fi

    echo -e "${GREEN}✓ SSH key ready${NC}"
fi

# Configure SSH config
if ! grep -q "homeserver-" "$HOME/.ssh/config" 2>/dev/null; then
    echo "Configuring SSH aliases..."
    cat >> "$HOME/.ssh/config" << 'EOF'

# Homeserver Infrastructure
Host homeserver-*
    IdentityFile ~/.ssh/homeserver_ed25519
    StrictHostKeyChecking no

Host homeserver-proxmox
    HostName 192.168.2.50
    User root

Host homeserver-nginx
    HostName 192.168.2.10
    User dincer

Host homeserver-immich
    HostName 192.168.2.202
    User root

Host homeserver-ha
    HostName 192.168.2.206
    User root
EOF
    echo -e "${GREEN}✓ SSH config updated${NC}"
fi

# Step 5: Configure Environment Variables
echo -e "\n${BLUE}[5/6] Configuring environment...${NC}"

SHELL_RC="$HOME/.zshrc"
if [ ! -f "$SHELL_RC" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

# Remove old homeserver config if exists
sed -i.bak '/# Homeserver Infrastructure as Code/,/^$/d' "$SHELL_RC" 2>/dev/null || true

# Add new configuration
cat >> "$SHELL_RC" << EOF

# Homeserver Infrastructure as Code
export TF_VAR_proxmox_user="root@pam"
export TF_VAR_proxmox_api_url="https://192.168.2.50:8006/api2/json"
export TF_VAR_proxmox_node="pve1"
export TF_VAR_network_gateway="192.168.2.1"
export TF_VAR_network_bridge="vmbr0"
export TF_VAR_dns_servers="192.168.2.1 8.8.8.8"
export TF_VAR_storage_pool="local-lvm"
export TF_VAR_iso_storage="local"

EOF

if [ "$USE_1PASSWORD" = true ]; then
    cat >> "$SHELL_RC" << 'EOF'
# Load password from 1Password
export TF_VAR_proxmox_password=$(op read "op://Homelab/Proxmox/password" 2>/dev/null)
EOF
elif [ "$MACHINE" = "Mac" ]; then
    cat >> "$SHELL_RC" << 'EOF'
# Load password from macOS Keychain
export TF_VAR_proxmox_password=$(security find-generic-password -a "$(whoami)" -s "proxmox-password" -w 2>/dev/null)
EOF
else
    cat >> "$SHELL_RC" << EOF
# Set password from environment
export TF_VAR_proxmox_password="$PROXMOX_PASSWORD"
EOF
fi

cat >> "$SHELL_RC" << 'EOF'

# Quick alias to verify
alias tf-check='echo "Proxmox User: $TF_VAR_proxmox_user" && echo "Password Set: $([ -n "$TF_VAR_proxmox_password" ] && echo "✅ Yes" || echo "❌ No")"'
EOF

echo -e "${GREEN}✓ Environment configured${NC}"

# Load environment for this session
export TF_VAR_proxmox_password="$PROXMOX_PASSWORD"
export TF_VAR_proxmox_user="root@pam"
export TF_VAR_proxmox_api_url="https://192.168.2.50:8006/api2/json"

# Step 6: Initialize Terraform and git-secrets
echo -e "\n${BLUE}[6/6] Finalizing setup...${NC}"

# Initialize Terraform
if [ -d "terraform" ]; then
    cd terraform
    terraform init -upgrade
    cd ..
    echo -e "${GREEN}✓ Terraform initialized${NC}"
fi

# Set up git-secrets
if command -v git-secrets &> /dev/null; then
    git secrets --install 2>/dev/null || true
    git secrets --register-aws 2>/dev/null || true
    echo -e "${GREEN}✓ git-secrets configured${NC}"
fi

# Create/update Ansible vault password file
if [ -f "ansible/.vault_pass" ]; then
    echo -e "${GREEN}✓ Ansible vault password already configured${NC}"
else
    echo -e "${YELLOW}Creating Ansible vault password...${NC}"
    VAULT_PASS=$(openssl rand -base64 32)
    echo "$VAULT_PASS" > ansible/.vault_pass
    chmod 600 ansible/.vault_pass

    if [ "$USE_1PASSWORD" = true ]; then
        # Save to 1Password
        echo "$VAULT_PASS" | op item create --category=password \
            --title="Ansible Vault Password" \
            --vault="Homelab" \
            password="$VAULT_PASS" 2>/dev/null || echo "Couldn't save vault password to 1Password"
    fi
fi

# Summary
echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Setup Complete! ✓                                       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}What was configured:${NC}"
echo "  ✓ Terraform & Ansible installed"
echo "  ✓ Secrets configured"
echo "  ✓ SSH keys ready"
echo "  ✓ Environment variables set"
echo "  ✓ git-secrets protection enabled"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Open a new terminal (to load environment)"
echo "  2. cd ~/homeserver-iac"
echo "  3. Test: terraform plan"
echo "  4. Test: ansible all -m ping"
echo ""
echo -e "${YELLOW}To copy SSH key to servers:${NC}"
echo "  ssh-copy-id -i ~/.ssh/homeserver_ed25519 dincer@192.168.2.10"
echo "  ssh-copy-id -i ~/.ssh/homeserver_ed25519 root@192.168.2.50"
echo ""
echo -e "${GREEN}Happy Infrastructure as Coding! 🚀${NC}"
