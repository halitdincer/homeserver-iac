# Operations

## Terraform (via Atlantis)

```bash
# Make changes, push to a branch, open PR
git checkout -b infra/my-change
git push -u origin HEAD
# → Atlantis posts terraform plan as PR comment (~30s)
# → Merge PR → Atlantis applies automatically

# Check pending plan output
# Visit https://atlantis.halitdincer.com or read PR comments

# Inspect state read-only (safe)
kubectl exec -n atlantis deploy/atlantis -- \
  terraform show /atlantis-home/state/terraform.tfstate
```

Never run `terraform apply` locally. State lives at `/atlantis-home/state/terraform.tfstate` on the Atlantis PVC.

## K3s / ArgoCD

```bash
# Check sync status of all apps
kubectl get applications -n argocd -o wide

# Force sync a specific app
kubectl patch application <app-name> -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'

# Get pods (all namespaces)
kubectl get pods --all-namespaces

# Port-forward Vault UI
kubectl port-forward -n vault vault-0 8200:8200
```

## Vault Secrets

```bash
# Read
kubectl exec -n vault vault-0 -- vault kv get secret/atlantis/config

# Patch (non-destructive, updates listed keys only)
kubectl exec -n vault vault-0 -- vault kv patch secret/atlantis/config KEY=value

# Put (overwrites all keys)
kubectl exec -n vault vault-0 -- vault kv put secret/myapp/config key1=val1 key2=val2
```

See `docs/SECRETS.md` for the full Vault paths table.

## Ansible

```bash
# Run all playbooks
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/all.yml

# Run a specific playbook
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/immich.yml

# Connectivity check
ansible all -i ansible/inventory/hosts.yml -m ping
```

## VM Management (Proxmox)

```bash
# List all VMs and status
ssh -i ~/.ssh/id_ed25519 root@192.168.2.50 "qm list"

# Show VM config
ssh -i ~/.ssh/id_ed25519 root@192.168.2.50 "qm config 105"
```

## Monitoring URLs

| Service | URL |
|---------|-----|
| ArgoCD | https://argocd.halitdincer.com |
| Atlantis | https://atlantis.halitdincer.com |
| Grafana | https://grafana.halitdincer.com |
| Gatus (uptime) | https://status.halitdincer.com |
| Homepage | https://home.halitdincer.com |

## Adding a New K3s App

1. Store secrets in Vault: `vault kv put secret/myapp/config ...`
2. Create `ExternalSecret` manifest in `k3s-manifests/apps/` (see existing examples)
3. Create Deployment / Service / Ingress manifests in `k3s-manifests/apps/`
4. Add `Application` YAML to `k3s-manifests/argocd-apps/`; `kubectl apply` it once to bootstrap
5. Push to `main` — ArgoCD picks up and deploys; ESO syncs secrets automatically
