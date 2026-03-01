# homeserver-iac — Agent Ops Bible

Proxmox VE 9.1.1 on Dell OptiPlex (192.168.2.50). Managed via Terraform (VMs + DNS), ArgoCD (K3s services), and Ansible (VM config).

## VMs

| VMID | IP | Service | URL |
|------|----|---------|-----|
| 100 | 192.168.2.202 | Immich (photos) | photos.halitdincer.com |
| 103 | 192.168.2.206 | Home Assistant OS | ha.halitdincer.com |
| 106 | 192.168.2.209 | devbox (AI coding agents) | devbox.halitdincer.com |
| 105 | 192.168.2.216 | K3s (ingress + all services) | argocd.halitdincer.com |

VM 103: no SSH — HAOS only, use REST API at port 8123.

## K3s Apps (ArgoCD managed)

| ArgoCD App | Path / Source | Purpose |
|------------|--------------|---------|
| `infrastructure` | `k3s-manifests/infrastructure/` | nginx ingress, cert-manager, ClusterSecretStore |
| `apps` | `k3s-manifests/apps/` | Atlantis, Coder, homepage, monitoring, vault-unsealer |
| `ingresses` | `k3s-manifests/ingresses/` | All nginx Ingress resources |
| `job-scout` | `k3s-manifests/job-scout/` | job-scout app (kustomize) |
| `vault` | Helm: hashicorp/vault@0.29.1 | HashiCorp Vault (standalone Raft) |
| `external-secrets` | Helm: external-secrets@0.14.0 | External Secrets Operator (ESO) |

## Deployment Tools

| Tool | Trigger | Rule |
|------|---------|------|
| Terraform | PR merge → Atlantis applies | Never `terraform apply` locally |
| ArgoCD | Push to `main` → auto-sync (~3 min) | Never `kubectl apply` directly |
| Ansible | Manual CLI only | `ansible-playbook -i ansible/inventory/hosts.yml ...` |

## Hard Rules

- **Never** `terraform apply` locally — Atlantis owns all applies via PR merge
- **Never** `kubectl apply` K3s resources — ArgoCD `selfHeal` reverts manual changes
- **Never** `kubectl create secret` or use SealedSecrets for app secrets — use Vault + ExternalSecret
- **Never** commit secrets (`terraform.tfvars`, `hosts.yml`, `*.pem`, `*.key` are gitignored)
- **Never** delete VMs or data without explicit user confirmation
- Bootstrap exception: new ArgoCD Application objects may be `kubectl apply`-ed once
- Namecheap API IP whitelist must match Atlantis outbound IP — update at namecheap.com if plan fails with `Invalid request IP`

## Change Workflows

**Terraform (VMs / DNS):**
```bash
git checkout -b my-change && git push
# Open PR → Atlantis posts plan as comment → merge → Atlantis applies
```

**K3s service (ArgoCD):**
```bash
# Edit k3s-manifests/**/*.yaml → push to main → ArgoCD auto-syncs
```

**Ansible:**
```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/all.yml
ansible all -i ansible/inventory/hosts.yml -m ping
```

## Secrets

Vault → ESO ClusterSecretStore (`vault-backend`) → ExternalSecret → K8s Secret → Pod.
See `docs/SECRETS.md` for paths table, read/write commands, and how to add a new secret.

## SSH

| Host | Command |
|------|---------|
| Proxmox | `ssh -i ~/.ssh/id_ed25519 root@192.168.2.50` |
| K3s VM | `ssh -i ~/.ssh/id_ed25519 root@192.168.2.216` |
| Immich VM | `ssh -i ~/.ssh/id_ed25519 root@192.168.2.202` |
| devbox | `ssh -i ~/.ssh/id_ed25519 dincer@192.168.2.209` |

## Post-Outage Recovery

Vault auto-unseals within ~30s via `vault-unsealer` pod. If other components fail:

```bash
# 1. Restart ArgoCD
kubectl rollout restart deployment argocd-repo-server argocd-server \
  argocd-applicationset-controller argocd-notifications-controller -n argocd

# 2. Restart ESO (caches stale Vault state)
kubectl rollout restart deployment -n external-secrets

# 3. Verify (~2 min to stabilise)
kubectl get applications -n argocd -o wide
kubectl get externalsecret --all-namespaces
```
