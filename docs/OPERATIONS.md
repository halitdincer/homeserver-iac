# Operations

## K3s Apps (ArgoCD managed)

| ArgoCD App | Path / Source | Purpose |
|------------|--------------|---------|
| `infrastructure` | `k3s-manifests/infrastructure/` | nginx ingress, cert-manager, CSStore |
| `apps` | `k3s-manifests/apps/` | Atlantis, Coder, homepage, monitoring |
| `ingresses` | `k3s-manifests/ingresses/` | All Ingress resources |
| `job-scout` | `k3s-manifests/job-scout/` | job-scout (kustomize) |
| `vault` | Helm: hashicorp/vault@0.29.1 | Vault (standalone Raft) |
| `external-secrets` | Helm: external-secrets@0.14.0 | ESO |

## Change Workflows

| Tool | Trigger | Rule |
|------|---------|------|
| Terraform | PR merge → Atlantis applies | Never `terraform apply` locally |
| ArgoCD | Push to `main` → auto-sync (~3 min) | Never `kubectl apply` directly |
| Ansible | Manual CLI only | `ansible-playbook -i ansible/inventory/hosts.yml ...` |

## Repo Tooling

| Tool | Config | Purpose |
|------|--------|---------|
| Renovate | `renovate.json` | Weekly grouped PRs for Terraform providers, GitHub Actions, and pinned container images. Schedule: Monday before 8am PT. No auto-merge. |
| Gitleaks (pre-commit) | `.pre-commit-config.yaml` | Blocks commits containing secrets locally. Setup once: `brew install pre-commit && pre-commit install`. |
| Gitleaks (CI) | `.github/workflows/gitleaks.yml` | Same scan in CI on every PR + push to `main` — catches anyone bypassing the local hook. |
| Terraform lint | `.github/workflows/lint.yml` | `tflint` + `terraform validate` on changes under `terraform/`. |

Notes:
- Renovate cannot bump `:latest` image tags. Pin tags when adding new manifests.
- Renovate GitHub App must be installed at the repo level (one-time, browser-only step).
- Run `pre-commit run gitleaks --all-files` to scan full history on demand.

## SSH Access

All use `-i ~/.ssh/id_ed25519`:

| Host | User@IP |
|------|---------|
| Proxmox | `root@10.10.10.1` |
| K3s VM | `root@10.10.10.105` |
| Immich VM | `root@10.10.10.100` |
| devbox | `dincer@10.10.10.106` |

| Home Assistant | `root@10.10.10.103` (port 22, via Proxmox jump host) |

HA SSH requires "Advanced SSH & Web Terminal" add-on. Connect via jump host:
```bash
ssh -J root@100.117.57.21 -p 22 root@10.10.10.103
```

## Coder Templates (`k3s-manifests/coder-templates/`)

homeserver-iac, job-scout-dev, flight-tracker-dev, home-assistant-dev, personal-site-dev, kubernetes, python-scratch

## Home Assistant Config (`home-assistant/`)

Configuration is managed as code and deployed via Ansible:

```bash
# Deploy config (syncs files, validates, restarts if changed)
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy-ha-config.yml

# Dry run (see what would change)
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy-ha-config.yml --check --diff
```

| File | Purpose |
|------|---------|
| `configuration.yaml` | Core config (http, trusted_proxies, includes) |
| `automations.yaml` | Automation rules |
| `scripts.yaml` | Script sequences |
| `scenes.yaml` | Scene definitions |
| `packages/` | Modular config bundles (e.g. climate.yaml, lighting.yaml) |

**Note:** Device pairings, integrations, entity registry, and add-on installs are UI-only — not managed here.

## Common Commands

```bash
kubectl get applications -n argocd -o wide   # sync status
kubectl port-forward -n vault vault-0 8200   # Vault UI
ssh root@10.10.10.1 "qm list"               # list VMs
```

## URLs

ArgoCD: argocd.halitdincer.com | Atlantis: atlantis.halitdincer.com | Grafana: grafana.halitdincer.com | Gatus: status.halitdincer.com | Homepage: home.halitdincer.com

## Adding a New K3s App

1. Store secrets in Vault
2. Create `ExternalSecret` + Deployment/Service/Ingress in `k3s-manifests/apps/`
3. Add `Application` YAML to `k3s-manifests/argocd-apps/`; `kubectl apply` once
4. Push to `main` — ArgoCD deploys, ESO syncs secrets
