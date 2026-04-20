# homeserver-iac — Agent Guide

Proxmox VE 9.1.1 on Dell OptiPlex (10.10.10.1). Managed via Terraform (VMs + DNS), ArgoCD (K3s services), and Ansible (VM config). Public access via Cloudflare Tunnel.

## VMs

| VMID | IP | Service | URL |
|------|----|---------|-----|
| 100 | 10.10.10.100 | Immich (photos) | photos.halitdincer.com |
| 103 | 10.10.10.103 | Home Assistant OS | ha.halitdincer.com |
| 105 | 10.10.10.105 | K3s (ingress + all services) | argocd.halitdincer.com |
| 106 | 10.10.10.106 | devbox (AI coding agents) | devbox.halitdincer.com |

## Deployment Tools

| Tool | Trigger | Rule |
|------|---------|------|
| Terraform | PR merge → Atlantis applies | Never `terraform apply` locally |
| ArgoCD | Push to `main` → auto-sync (~3 min) | Never `kubectl apply` directly |
| Ansible | Manual CLI only | `ansible-playbook -i ansible/inventory/hosts.yml ...` |

## Hard Rules

- **Never** `terraform apply` locally — Atlantis owns all applies via PR merge
- **Never** `kubectl apply` K3s resources — ArgoCD `selfHeal` reverts manual changes
- **Never** `kubectl create secret` for app secrets — use Vault + ExternalSecret
- **Never** commit secrets (`terraform.tfvars`, `hosts.yml`, `*.pem`, `*.key` are gitignored)
- **Never** delete VMs or data without explicit user confirmation
- **Never** use `ifreload -a` on Proxmox — it kills WiFi and drops all connectivity
- Bootstrap exception: new ArgoCD Application objects may be `kubectl apply`-ed once
- Namecheap API IP whitelist must match Atlantis outbound IP

## Documentation Index

| Doc | Purpose |
|-----|---------|
| `docs/OPERATIONS.md` | K3s apps, workflows, SSH, Coder, common commands |
| `docs/NETWORK.md` | Topology, Cloudflare Tunnel, Tailscale, DNS |
| `docs/BACKUPS.md` | Backup strategy, playbooks, verification |
| `docs/SECRETS.md` | Vault paths, read/write commands, adding secrets |
| `docs/TROUBLESHOOTING.md` | Problem/solution pairs, recovery procedures |

## Doc Maintenance

After modifying `terraform/`, `k3s-manifests/`, or `ansible/` files, update the relevant doc:

| Changed file pattern | Update doc |
|---------------------|-----------|
| `terraform/dns.tf`, ingresses, tunnel config | `docs/NETWORK.md` |
| K3s apps, ArgoCD apps, Coder templates | `docs/OPERATIONS.md` |
| ExternalSecret manifests, Vault config | `docs/SECRETS.md` |
| Ansible backup playbooks | `docs/BACKUPS.md` |

Claude Code users: run `/update-docs` to auto-detect and apply.
