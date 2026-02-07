#!/bin/bash

# Script to switch between local and Tailscale access for Proxmox

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFVARS_FILE="$SCRIPT_DIR/terraform/terraform.tfvars"

LOCAL_IP="192.168.2.50"
TAILSCALE_IP="100.117.57.21"

case "${1:-}" in
    local)
        echo "Switching to LOCAL network access (192.168.2.50)..."
        if [ -f "$TFVARS_FILE" ]; then
            sed -i.bak "s|https://$TAILSCALE_IP:8006/api2/json|https://$LOCAL_IP:8006/api2/json|g" "$TFVARS_FILE"
            echo "✅ Updated terraform.tfvars to use local IP"
        fi
        export TF_VAR_proxmox_api_url="https://$LOCAL_IP:8006/api2/json"
        echo "✅ Set environment variable for local access"
        echo ""
        echo "You can now run Terraform commands from home network."
        ;;

    remote|tailscale)
        echo "Switching to TAILSCALE access (100.117.57.21)..."
        if [ -f "$TFVARS_FILE" ]; then
            sed -i.bak "s|https://$LOCAL_IP:8006/api2/json|https://$TAILSCALE_IP:8006/api2/json|g" "$TFVARS_FILE"
            echo "✅ Updated terraform.tfvars to use Tailscale IP"
        fi
        export TF_VAR_proxmox_api_url="https://$TAILSCALE_IP:8006/api2/json"
        echo "✅ Set environment variable for Tailscale access"
        echo ""
        echo "You can now run Terraform commands from anywhere!"
        echo ""
        echo "NOTE: Run this in your current shell:"
        echo "  export TF_VAR_proxmox_api_url=\"https://$TAILSCALE_IP:8006/api2/json\""
        ;;

    status)
        echo "Current Proxmox connectivity:"
        echo ""
        echo "Local IP (192.168.2.50):"
        if ping -c 1 -W 1 $LOCAL_IP &>/dev/null; then
            echo "  ✅ Reachable"
        else
            echo "  ❌ Not reachable (you're not on home network)"
        fi

        echo ""
        echo "Tailscale IP (100.117.57.21):"
        if ping -c 1 -W 1 $TAILSCALE_IP &>/dev/null; then
            echo "  ✅ Reachable via Tailscale"
        else
            echo "  ❌ Not reachable (Tailscale may be disconnected)"
        fi

        echo ""
        echo "Terraform config:"
        if [ -f "$TFVARS_FILE" ]; then
            CURRENT_URL=$(grep proxmox_api_url "$TFVARS_FILE" | head -1)
            echo "  $CURRENT_URL"
        fi

        echo ""
        echo "Environment variable:"
        if [ -n "$TF_VAR_proxmox_api_url" ]; then
            echo "  TF_VAR_proxmox_api_url=$TF_VAR_proxmox_api_url"
        else
            echo "  Not set (will use terraform.tfvars value)"
        fi
        ;;

    *)
        echo "Usage: $0 {local|remote|status}"
        echo ""
        echo "Commands:"
        echo "  local    - Switch to local network (192.168.2.50)"
        echo "  remote   - Switch to Tailscale (100.117.57.21)"
        echo "  status   - Check current connectivity"
        echo ""
        echo "Examples:"
        echo "  $0 local    # At home"
        echo "  $0 remote   # At coffee shop"
        echo "  $0 status   # Check what's reachable"
        exit 1
        ;;
esac
