---
name: update-ops-docs
description: Update docs/OPERATIONS.md when K3s apps, workflows, or service config changes.
---

# Update Operations Documentation

Update `docs/OPERATIONS.md` to reflect changes in K3s apps, workflows, or service configuration.

## When to Run

After changes to:
- `k3s-manifests/apps/` (application deployments)
- `k3s-manifests/argocd-apps/` (ArgoCD Application resources)
- `k3s-manifests/infrastructure/` (cluster infrastructure)
- `k3s-manifests/coder-templates/` (Coder workspace templates)
- Any new ArgoCD-managed app or Helm chart

## Sections to Check

1. **K3s Apps table** — app name, path/source, purpose
2. **Change Workflows** — tool triggers and rules
3. **SSH Access** — VM IPs and usernames
4. **Coder Templates** — available workspace templates
5. **Common Operations** — kubectl commands, port-forwards
6. **Monitoring URLs** — service URLs
7. **Adding a New K3s App** — steps still accurate

## Rules

- Keep under 2KB total
- If a new ArgoCD app is added, add a row to the K3s Apps table
- If a new Coder template directory appears, add it to the Coder Templates table
- If a monitoring URL changes or is added, update the Monitoring URLs table
- Do not duplicate content from `docs/SECRETS.md` or `docs/NETWORK.md`
