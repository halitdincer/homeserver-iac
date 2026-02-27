# homeserver-iac

Infrastructure-as-code for a Proxmox VE 9.1.1 homeserver (Dell OptiPlex, `192.168.2.50`). Three tools manage everything: **Terraform** provisions VMs and DNS records, **ArgoCD** deploys all K3s services via GitOps, and **Ansible** handles VM-level configuration. Domain: `halitdincer.com` (Namecheap DNS via Terraform).

## VMs

| VMID | IP | Service | Notes |
|------|----|---------|-------|
| 100 | 192.168.2.202 | Immich (photos) | Ubuntu 24.04 |
| 103 | 192.168.2.206 | Home Assistant OS | HAOS 16.3, no SSH |
| 104 | 192.168.2.208 | OpenClaw (AI assistant) | Tailscale-only access |
| 105 | 192.168.2.216 | K3s cluster | Runs all services below |

## K3s Apps

| Group | Services |
|-------|---------|
| Infrastructure | nginx ingress, cert-manager, External Secrets Operator |
| Platform | HashiCorp Vault, ArgoCD, Atlantis |
| Tools | Coder (code-server), Homepage dashboard |
| Projects | job-scout |

## How Changes Are Made

- **Terraform** (VMs, DNS): open a PR → Atlantis plans and applies on merge
- **K3s services**: push changes to `k3s-manifests/` on `main` → ArgoCD auto-syncs
- **VM config**: run Ansible playbooks manually from your local machine

## Repo Layout

```
terraform/          VM + DNS definitions (bpg/proxmox, namecheap)
ansible/            VM configuration playbooks
k3s-manifests/      ArgoCD-managed K8s manifests
docs/               OPERATIONS.md  SECRETS.md  TROUBLESHOOTING.md
```

## Key URLs

| Service | URL |
|---------|-----|
| ArgoCD | https://argocd.halitdincer.com |
| Atlantis | https://atlantis.halitdincer.com |
| Homepage | https://home.halitdincer.com |
| Grafana | https://grafana.halitdincer.com |
| Gatus | https://status.halitdincer.com |

---

For AI agents: see [CLAUDE.md](./CLAUDE.md).
