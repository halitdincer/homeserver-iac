# Home Server Infrastructure as Code

Proxmox VE 9.1.1 home server on a Dell OptiPlex at 192.168.2.50 (node: `pve1`).
Managed with **Terraform** (provisioning + DNS) and **Ansible** (configuration/deployment).
Domain: `halitdincer.com` (Namecheap, DNS managed via Terraform). DDNS via No-IP (`halitdincer.ddns.net`).

## VMs and Services

| VMID | Terraform Resource | IP | Service | Port | URL |
|------|-------------------|-----|---------|------|-----|
| 100 | `proxmox_virtual_environment_vm.immich` | 192.168.2.202 | Immich (photos) | 2283 | photos.halitdincer.com |
| 103 | `proxmox_virtual_environment_vm.home_assistant` | 192.168.2.206 | Home Assistant OS | 8123 | ha.halitdincer.com |
| 104 | `proxmox_virtual_environment_vm.openclaw` | 192.168.2.208 (Tailscale: 100.82.144.118) | OpenClaw (AI assistant) | 18789, 18790 | openclaw.halitdincer.com (Tailscale-only) |
| 105 | `proxmox_virtual_environment_vm.k3s` | 192.168.2.216 | K3s (ingress, ArgoCD, cert-manager, Vault, ESO) | 80,443 | argocd.halitdincer.com |

All Ubuntu VMs run 24.04.3 LTS with Docker. Home Assistant runs HAOS 16.3 (no SSH - use REST API).

## Network Topology

```
Internet → Router (192.168.2.1, ports 80/443) → K3s nginx ingress (192.168.2.216)
  ├── photos.halitdincer.com    → 192.168.2.202:2283 (Immich)
  ├── ha.halitdincer.com        → 192.168.2.206:8123 (Home Assistant)
  └── argocd.halitdincer.com    → K3s internal (ArgoCD)

Tailscale VPN (tailnet: halitdincer.github)
  ├── openclaw.halitdincer.com:18789  → 100.82.144.118 (OpenClaw Lyra)
  └── openclaw-house.halitdincer.com:18790 → 100.82.144.118 (OpenClaw House)
  Access: SSH tunnel over Tailscale SSH (no keys needed)
    ssh dincer@100.82.144.118 -L 18789:localhost:18789
    ssh dincer@100.82.144.118 -L 18790:localhost:18790

Proxmox host: 192.168.2.50:8006
DNS: *.halitdincer.com → CNAME → halitdincer.ddns.net → public IP (managed in terraform/dns.tf)
     openclaw/openclaw-house.halitdincer.com → A record → 100.82.144.118 (Tailscale IP)
SSL: Let's Encrypt via cert-manager (K3s); OpenClaw uses plain HTTP over Tailscale (WireGuard-encrypted)
```

## Project Structure

```
terraform/
  main.tf          - Provider config (bpg/proxmox v0.70, namecheap/namecheap v2.0, local backend)
  vms.tf           - All VM definitions (EDIT HERE for VM changes)
  dns.tf           - DNS records for halitdincer.com (Namecheap API)
  variables.tf     - Input variables (node, network, storage, Namecheap API)
  outputs.tf       - VM info outputs
  terraform.tfvars - Credentials (GITIGNORED, never commit)

ansible/
  inventory/hosts.yml  - Host inventory with IPs (GITIGNORED)
  playbooks/
    all.yml              - Master playbook (runs all below)
    immich.yml           - Immich deployment
    home-assistant.yml   - Home Assistant management
    openclaw.yml         - OpenClaw deployment
    backup.yml           - Backup configuration
  secrets.yml        - Ansible vault encrypted secrets
  ansible.cfg        - Ansible config (GITIGNORED)

docs/                - Extended documentation (setup, operations, troubleshooting)
```

## Terraform workflow — Atlantis (GitOps)

**Do not run `terraform apply` locally.** All Terraform changes go through Atlantis.

```
Edit *.tf files → push to a branch → open PR
  → Atlantis posts terraform plan as PR comment  (~30s)
  → Review plan → merge PR
  → Atlantis applies automatically
```

Atlantis URL: https://atlantis.halitdincer.com
Webhook: `POST https://atlantis.halitdincer.com/events` (already configured on the repo)
State file: persisted at `/atlantis-home/state/terraform.tfstate` in Atlantis PVC on K3s
Config: `atlantis.yaml` at repo root

**Rules for Terraform:**
- **Never run `terraform apply` locally** — Atlantis owns apply
- **Never run `terraform plan` and show output as if it's a deployment** — just push and let Atlantis plan
- `terraform plan` locally is OK for quick iteration, but apply only via PR merge
- Changes to `terraform/dns.tf` are rate-limited by Namecheap API — avoid plan/apply loops
- Always push `*.tf` changes to a branch, not directly to `main`

## Ansible commands (still manual)

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/all.yml
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/immich.yml
ansible all -i ansible/inventory/hosts.yml -m ping  # connectivity check
```

## K3s / ArgoCD — GitOps for services

ArgoCD manages `k3s-manifests/` directories. Changes to those files deploy automatically when pushed to `main`:

| ArgoCD App | Watches | Deploys |
|---|---|---|
| `apps` | `k3s-manifests/apps/` | Atlantis, code-server, homepage, uptime-kuma, monitoring, etc. |
| `ingresses` | `k3s-manifests/ingresses/` | All nginx ingress resources |
| `infrastructure` | `k3s-manifests/infrastructure/` | nginx, cert-manager, ArgoCD Image Updater, ClusterSecretStore |
| `job-scout` | `k3s-manifests/job-scout/` | job-scout deployment (kustomize) |
| `vault` | Helm: `hashicorp/vault@0.29.1` | HashiCorp Vault (standalone Raft) |
| `external-secrets` | Helm: `external-secrets/external-secrets@0.14.0` | External Secrets Operator |

**Rules for K3s:**
- **Never** `kubectl apply` K3s resources directly — ArgoCD `selfHeal` will revert them
- To change a service: edit `k3s-manifests/`, push to `main`, ArgoCD auto-syncs within ~3 min
- To bootstrap a NEW ArgoCD Application: add YAML to `k3s-manifests/argocd-apps/` then `kubectl apply` it once
- Helm-based apps (vault, external-secrets) are defined entirely in `k3s-manifests/argocd-apps/` — no separate manifests dir

## Secrets — Vault + External Secrets Operator

All application secrets are stored in **HashiCorp Vault** and synced into K8s Secrets by ESO.

**Vault paths:**
| App | Vault Path | K8s Secret |
|-----|-----------|------------|
| code-server | `secret/code-server/config` | `default/code-server-secret` |
| atlantis | `secret/atlantis/config` | `atlantis/atlantis-env` |
| job-scout | `secret/job-scout/config` | `job-scout/job-scout-secret` |

**Read/write secrets:**
```bash
# View a secret
kubectl exec -n vault vault-0 -- vault kv get secret/atlantis/config

# Add or update a key (patch = non-destructive, only updates listed keys)
kubectl exec -n vault vault-0 -- vault kv patch secret/atlantis/config ATLANTIS_GH_TOKEN=new_token

# Overwrite all keys at once
kubectl exec -n vault vault-0 -- vault kv put secret/myapp/config key1=val1 key2=val2
```

**Add a new app secret:**
1. Store in Vault: `kubectl exec -n vault vault-0 -- vault kv put secret/myapp/config ...`
2. Create ExternalSecret in the app's manifest dir (see existing ones as examples)
3. Reference `secretStoreRef.name: vault-backend`, `kind: ClusterSecretStore`
4. Push to main — ArgoCD syncs, ESO creates the K8s Secret automatically

**Vault UI (port-forward):**
```bash
kubectl port-forward -n vault vault-0 8200:8200
# open http://localhost:8200  (token from password manager)
```

**⚠️ Vault is sealed after every restart.** Unseal with 2 of 3 keys from password manager:
```bash
kubectl exec -n vault vault-0 -- vault operator unseal <KEY1>
kubectl exec -n vault vault-0 -- vault operator unseal <KEY2>
```

**Do NOT use SealedSecrets or `kubectl create secret` for new app secrets** — use Vault + ExternalSecret instead.

## Check VM status

```bash
ssh root@192.168.2.50 "qm list"
ssh root@192.168.2.50 "qm config 100"
```

## SSH Access

SSH aliases are configured in `~/.ssh/config` (key: `~/.ssh/homeserver_ed25519`):

| Host alias | Raw SSH | Notes |
|---|---|---|
| `ssh homeserver-proxmox` | `ssh root@192.168.2.50` | Proxmox host |
| `ssh homeserver-immich` | `ssh root@192.168.2.202` | Immich VM |
| `ssh homeserver-k3s` | `ssh root@192.168.2.216` | K3s VM |
| `ssh homeserver-openclaw` | `ssh dincer@192.168.2.208` | OpenClaw (LAN, key-based) |
| `ssh homeserver-openclaw-ts` | `ssh dincer@100.82.144.118` | OpenClaw (Tailscale SSH, no keys) |

- **Home Assistant (VM 103)**: No SSH. HAOS only — use REST API at port 8123

## USB Passthrough

- VM 100 (Immich): Card reader `0bda:9210` for SD card photo imports
- VM 103 (Home Assistant): Zigbee coordinator `1a86:7523` for smart home devices

## Rules

- **Never commit secrets**: `terraform.tfvars`, `ansible.cfg`, `hosts.yml`, `*.pem`, `*.key` are gitignored
- **Never use SealedSecrets or `kubectl create secret` for new app secrets** — use Vault + ExternalSecret
- **Never run `terraform apply` locally** — all applies go through Atlantis via PR merge
- **Never `kubectl apply` K3s resources directly** — ArgoCD selfHeal reverts manual changes
- **Don't delete VMs or data** without explicit user confirmation
- **Ansible vault** for sensitive data: `ansible-vault edit ansible/secrets.yml`
- **All VMs use static IPs** configured inside the VM (not DHCP)
- **Lifecycle ignores**: All VMs ignore changes to `network_device`, `disk`, and `started` in Terraform to avoid drift issues
- When adding a new VM/service: create in `terraform/vms.tf`, add to `ansible/inventory/hosts.yml`, create playbook in `ansible/playbooks/`, add K8s manifests in `k3s-manifests/`
- **DNS changes**: Edit `terraform/dns.tf`. Namecheap API has rate limits — avoid frequent plan/apply cycles.
- **Backend**: local state at `/atlantis-home/state/terraform.tfstate` (on Atlantis PVC). Do not change the backend type.

## Terraform Provider Details

- Provider: `bpg/proxmox` v0.70 (resource type: `proxmox_virtual_environment_vm`)
- Provider: `namecheap/namecheap` v2.0 (resource type: `namecheap_domain_records`)
- Auth: username/password via `terraform.tfvars` (root@pam for Proxmox, API key for Namecheap)
- SSL: insecure mode (self-signed Proxmox cert)
- Backend: local, state at `/atlantis-home/state/terraform.tfstate` (Atlantis PVC on K3s). Apply via Atlantis only.
- All VMs: UEFI (OVMF), Q35 machine, virtio network, storage on `local-lvm`
