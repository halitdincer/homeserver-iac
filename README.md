# homeserver-iac

Infrastructure-as-code for a Proxmox VE 9.1.1 homeserver (Dell OptiPlex). **Terraform** provisions VMs and DNS, **ArgoCD** deploys K3s services via GitOps, **Ansible** handles VM config. Public access via Cloudflare Tunnel; private via Tailscale.

## VMs

| VMID | IP | Service |
|------|----|---------|
| 100 | 10.10.10.100 | Immich (photos) |
| 103 | 10.10.10.103 | Home Assistant OS |
| 105 | 10.10.10.105 | K3s (all services) |
| 106 | 10.10.10.106 | devbox (AI agents) |

## How Changes Are Made

- **Terraform** (VMs, DNS): PR → Atlantis plans → merge → applies
- **K3s services**: push to `k3s-manifests/` on `main` → ArgoCD auto-syncs
- **VM config**: run Ansible playbooks manually

## Repo Layout

```
terraform/          VM + DNS definitions (Proxmox, Cloudflare, Namecheap)
ansible/            VM configuration and backup playbooks
k3s-manifests/      ArgoCD-managed K8s manifests
docs/               Focused documentation (see below)
```

## Documentation

| Doc | Content |
|-----|---------|
| [Operations](docs/OPERATIONS.md) | K3s apps, workflows, SSH, Coder templates |
| [Network](docs/NETWORK.md) | Topology, Cloudflare Tunnel, Tailscale, DNS |
| [Backups](docs/BACKUPS.md) | Strategy, Ansible playbooks, verification |
| [Secrets](docs/SECRETS.md) | Vault paths, ESO, adding new secrets |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Problem/solution pairs, recovery |

---

For AI agents: see [CLAUDE.md](./CLAUDE.md).
