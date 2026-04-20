# homeserver-iac — Agent Ops Bible

Proxmox VE 9.1.1 on Dell OptiPlex (10.10.10.1). Managed via Terraform (VMs + DNS), ArgoCD (K3s services), and Ansible (VM config). Public access is via Cloudflare Tunnel (not port forwarding).

## VMs

| VMID | IP | Service | URL |
|------|----|---------|-----|
| 100 | 10.10.10.100 | Immich (photos) | photos.halitdincer.com |
| 103 | 10.10.10.103 | Home Assistant OS | ha.halitdincer.com |
| 105 | 10.10.10.105 | K3s (ingress + all services) | argocd.halitdincer.com |
| 106 | 10.10.10.106 | devbox (AI coding agents) | devbox.halitdincer.com |

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
| Proxmox | `ssh -i ~/.ssh/id_ed25519 root@10.10.10.1` |
| K3s VM | `ssh -i ~/.ssh/id_ed25519 root@10.10.10.105` |
| Immich VM | `ssh -i ~/.ssh/id_ed25519 root@10.10.10.100` |
| devbox | `ssh -i ~/.ssh/id_ed25519 dincer@10.10.10.106` |

## Post-Outage Recovery

Fully automated via `vault-unsealer` pod (two containers):
1. **unsealer** — detects sealed Vault, submits unseal keys (~30s)
2. **recovery** — detects unseal event, waits for Vault readiness, then restarts ArgoCD and ESO

Manual intervention should not be needed. To verify recovery:

```bash
kubectl get applications -n argocd -o wide
kubectl get externalsecret --all-namespaces
kubectl logs deployment/vault-unsealer -n vault -c recovery --tail=20
```

If automated recovery fails, manual fallback:

```bash
kubectl rollout restart deployment argocd-repo-server argocd-server \
  argocd-applicationset-controller argocd-notifications-controller -n argocd
kubectl rollout restart deployment -n external-secrets
```
