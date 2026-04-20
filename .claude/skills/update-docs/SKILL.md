---
name: update-docs
description: Update documentation after infrastructure changes. Invoke after modifying terraform/, k3s-manifests/, or ansible/ files.
---

# Update Documentation

Detect what changed and update the relevant documentation file(s).

## Steps

1. Run `git diff --name-only HEAD~1` (or `git diff --name-only` for uncommitted changes) to get the list of changed files.

2. Use this mapping to determine which doc(s) to update:

| Changed file pattern | Update |
|---------------------|--------|
| `terraform/dns.tf`, `k3s-manifests/ingresses/`, tunnel/cloudflared config | `docs/NETWORK.md` |
| `k3s-manifests/apps/`, `k3s-manifests/argocd-apps/`, `k3s-manifests/coder-templates/`, `k3s-manifests/infrastructure/` | `docs/OPERATIONS.md` |
| `*secret*`, `*external-secret*`, Vault manifests | `docs/SECRETS.md` |
| `ansible/playbooks/backup*` | `docs/BACKUPS.md` |
| Network topology, NAT, dnsmasq, nftables, Tailscale | `docs/NETWORK.md` |
| VM definitions (`terraform/vms.tf`) | `CLAUDE.md` VM table |

3. Read the relevant doc file AND the changed source files.

4. Update the doc to reflect the new reality. Rules:
   - Keep each doc under 2KB
   - Use tables over prose
   - Only update sections affected by the change
   - Do not add speculative content — only document what exists in code

5. If a VM was added/removed/changed IP, also update the VM table in `CLAUDE.md`.

## Format Guidelines

- Tables for structured data (IPs, paths, URLs, mappings)
- Code blocks for commands (```bash)
- One blank line between sections
- No emoji, no badges, no decorative elements
