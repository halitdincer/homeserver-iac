---
name: update-secrets-docs
description: Update docs/SECRETS.md when ExternalSecret manifests or Vault config changes.
---

# Update Secrets Documentation

Update `docs/SECRETS.md` to reflect changes in ExternalSecret manifests or Vault configuration.

## When to Run

After changes to:
- `k3s-manifests/apps/*secret*` (ExternalSecret resources)
- `k3s-manifests/infrastructure/external-secrets*` (ESO operator config)
- Vault Helm chart configuration
- ClusterSecretStore definitions

## Sections to Check

1. **Vault Paths table** — app name, Vault path, K8s secret name, namespace
2. **Read/Write Commands** — still accurate examples
3. **Adding a New App Secret** — steps still valid
4. **SealedSecrets Note** — only for vault-unsealer bootstrap

## Rules

- Keep under 2KB total
- If a new ExternalSecret manifest is added, add a row to the Vault Paths table
- Extract the Vault path from `dataFrom[].extract.key` or `data[].remoteRef.key`
- Extract the K8s secret name from `spec.target.name` (or metadata.name if target omitted)
- Extract namespace from the manifest's `metadata.namespace`
- Do not list individual secret keys — only the path and secret name
