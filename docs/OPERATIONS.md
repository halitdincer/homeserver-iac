# Operations

## K3s Apps (ArgoCD managed)

| ArgoCD App | Path / Source | Purpose |
|------------|--------------|---------|
| `infrastructure` | `k3s-manifests/infrastructure/` | nginx ingress, ClusterIssuers, wildcard cert, CSStore, image-updater |
| `apps` | `k3s-manifests/apps/` | Coder, single-file manifests for the remaining hand-rolled services |
| `homepage` | `k3s-manifests/apps/homepage/` (Helm: jameswynn/homepage@2.1.0) | Homepage dashboard (wrapper chart + custom templates) |
| `atlantis` | `k3s-manifests/apps/atlantis/` (Helm: runatlantis/atlantis@6.3.0, image v0.31.0) | Atlantis Terraform GitOps (wrapper chart + custom templates) |
| `alloy` | Helm: grafana/alloy@1.8.0 (DaemonSet) | Cloud-bound observability agent — discovers ServiceMonitors cluster-wide and `prometheus.remote_write`s metrics to Grafana Cloud Mimir; tails container logs and `loki.write`s them to Grafana Cloud Loki. Also scrapes the Proxmox host node_exporter directly. Replaces the deleted in-cluster `monitoring` and `loki` apps. |
| `ingresses` | `k3s-manifests/ingresses/` | Ingress resources for `apps`-tier services |
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

ArgoCD: argocd.halitdincer.com | Atlantis: atlantis.halitdincer.com | Gatus: status.halitdincer.com | Homepage: home.halitdincer.com | Grafana / dashboards / alerts: hosted on Grafana Cloud (your `*.grafana.net` stack — log in via grafana.com)

## Adding a New K3s App

**Hand-rolled (no upstream chart):**

1. Store secrets in Vault
2. Create `ExternalSecret` + Deployment/Service in `k3s-manifests/apps/`
3. Create Ingress in `k3s-manifests/ingresses/` — `host: foo.halitdincer.com`, no TLS config needed (the wildcard cert covers it; see NETWORK.md §TLS)
4. Add `Application` YAML to `k3s-manifests/argocd-apps/`; `kubectl apply` once
5. Push to `main` — ArgoCD deploys, ESO syncs secrets

**Wrapping an upstream Helm chart** (preferred when one exists — see `k3s-manifests/apps/homepage/` as the canonical example):

1. Create `k3s-manifests/apps/<app>/Chart.yaml` with the upstream chart pinned under `dependencies:`
2. Run `helm dependency build` once locally to generate `Chart.lock` (commit it; `charts/` is gitignored — ArgoCD re-fetches via the lock)
3. Override defaults in `values.yaml` (pin image tag — Renovate will bump it)
4. Add wrapper resources (Ingress, ExternalSecret, ConfigMap, RBAC) under `templates/` — these stay verbatim across chart bumps
5. Add a dedicated `Application` YAML in `k3s-manifests/argocd-apps/` with `path: k3s-manifests/apps/<app>` (ArgoCD auto-runs `helm dependency build`); `kubectl apply` once
6. Push to `main`

## Adding Metrics / Alerts to a K3s App

Alloy discovers `ServiceMonitor` CRDs cluster-wide (the
`monitoring.coreos.com/v1` CRDs are kept around even though kube-prometheus-stack
is gone) and remote_writes the scraped series to Grafana Cloud Mimir. Logs flow
through Alloy's `discovery.kubernetes` → `loki.source.kubernetes` →
Grafana Cloud Loki. So the in-cluster part is unchanged — only the storage and
UI moved off-cluster.

1. Expose `/metrics` from your app (HTTP handler on a known port, no auth).
2. Add a `ServiceMonitor` next to the app's `Service`:
   ```yaml
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: <app>
     namespace: <app-ns>
   spec:
     selector:
       matchLabels: { app: <app> }
     endpoints:
       - port: http        # named port on the Service
         path: /metrics
         interval: 30s
   ```
   Alloy picks it up within ~1 scrape cycle. Confirm in Cloud Grafana →
   Explore → Mimir: `up{job="<svc>", cluster="homeserver"}` should return 1.

3. **Alerts**: author Grafana-managed alert rules in `terraform/grafana.tf`
   (`grafana_rule_group` resources). They route to the `ntfy` contact point
   defined in the same file. Atlantis applies on PR merge; no in-cluster
   PrometheusRule CRs anymore (Alertmanager + ntfy-relay were deleted with
   the `monitoring` app).

4. **Dashboards**: drop a JSON file into `terraform/grafana-dashboards/` and
   register it in `grafana.tf`'s `local.dashboard_json_files` map. The
   `replace()` chain in the `grafana_dashboard` resource swaps the literal
   `"prometheus"` / `"loki"` datasource UIDs in the JSON with the live Cloud
   datasource UIDs at apply time, so dashboards exported from Cloud Grafana
   can be checked in verbatim.

External (non-K8s) targets like the Proxmox host live in the `prometheus.scrape`
block of `alloy`'s River config (`k3s-manifests/argocd-apps/helm-charts-appset.yaml`,
the `alloy` entry).
