# Secrets

## Architecture

Vault → ESO `ClusterSecretStore` (`vault-backend`) → `ExternalSecret` → K8s Secret → Pod env/volume.

Never use `kubectl create secret` or SealedSecrets for app secrets (SealedSecrets is only used for the vault-unsealer bootstrap secret).

## Vault Paths

| App | Vault path | K8s secret name | Namespace |
|-----|-----------|-----------------|-----------|
| atlantis | `secret/atlantis/config` (also holds `TF_VAR_*` keys for terraform vars, including `TF_VAR_grafana_auth_token`) | `atlantis-env` | atlantis |
| job-scout | `secret/job-scout/config` | `job-scout-secret` | job-scout |
| coder | `secret/coder/config` | `coder-secret` | coder |
| coder (homeserver-iac workspace) | `secret/coder/homeserver-iac` | `homeserver-iac-secret` | coder |
| coder (home-assistant workspace) | `secret/coder/home-assistant` | `home-assistant-secret` | coder |
| homepage | `secret/homepage/config` | `homepage-secret` | default |
| cert-manager (Cloudflare DNS-01) | `secret/cert-manager/config` (key: `cloudflare-api-token`) | `cloudflare-api-token` | cert-manager |
| Grafana Cloud (Alloy → Cloud Mimir/Loki) | `secret/grafana-cloud/config` (keys: `prom-url`, `prom-user`, `loki-url`, `loki-user`, `api-key`) | `grafana-cloud` | alloy |

## Read / Write Commands

```bash
# View a secret
kubectl exec -n vault vault-0 -- vault kv get secret/atlantis/config

# Update specific keys (non-destructive)
kubectl exec -n vault vault-0 -- vault kv patch secret/atlantis/config KEY=value

# Overwrite all keys at once
kubectl exec -n vault vault-0 -- vault kv put secret/myapp/config key1=val1 key2=val2
```

## Adding a New App Secret

1. Store in Vault:
   ```bash
   kubectl exec -n vault vault-0 -- vault kv put secret/myapp/config KEY=value
   ```
2. Create `ExternalSecret` in the app's manifest directory (copy an existing one):
   - `secretStoreRef.name: vault-backend`, `kind: ClusterSecretStore`
   - `dataFrom[0].extract.key: secret/myapp/config`
3. Push to `main` — ArgoCD syncs, ESO creates the K8s Secret automatically.
4. Reference the secret name in your Deployment env/volumes.

## Vault UI

```bash
kubectl port-forward -n vault vault-0 8200:8200
# Open http://localhost:8200 — token from password manager
```

## SealedSecrets Note

SealedSecrets is only used for the `vault-unsealer` bootstrap (stores unseal keys in git, encrypted with the cluster's sealed-secrets public key). For all other secrets, use Vault + ExternalSecret.

To seal a secret locally:
```bash
kubeseal --cert /tmp/sealed-secrets.crt --format yaml < secret.yaml
# Fetch cert: kubectl get secret -n kube-system sealed-secrets-keym852r \
#   -o jsonpath='{.data.tls\.crt}' | base64 -d
```

## Related Docs

- Operations workflows: `docs/OPERATIONS.md`
- Troubleshooting ESO sync issues: `docs/TROUBLESHOOTING.md` §3
