# Troubleshooting

## 1. Terraform plan fails: "Invalid request IP"

**Cause:** Namecheap API IP whitelist doesn't include Atlantis pod's outbound IP.

**Fix:** Log in to namecheap.com → Profile → Tools → API Access → add the current IP.
The Atlantis pod's IP changes when the K3s node restarts. Re-run the plan after whitelisting.

## 2. ArgoCD app stuck OutOfSync or Degraded

**Cause:** repo-server often fails to reconnect after abrupt shutdown or network hiccup.

**Fix:**
```bash
kubectl rollout restart deployment argocd-repo-server argocd-server \
  argocd-applicationset-controller argocd-notifications-controller -n argocd
kubectl get applications -n argocd -o wide  # wait ~2 min
```

## 3. ExternalSecret not syncing / secret missing

**Cause:** ESO caches the sealed Vault state and won't recover on its own after Vault restart.

**Fix:**
```bash
kubectl rollout restart deployment -n external-secrets
kubectl get externalsecret --all-namespaces  # should show Ready
```
Also verify the Vault path exists: `kubectl exec -n vault vault-0 -- vault kv get secret/myapp/config`

## 4. Vault sealed after restart

**Cause:** vault-unsealer pod hasn't polled yet (polls every 30s).

**Expected behaviour:** Wait ~30s — Vault auto-unseals automatically via `vault-unsealer` deployment.

**Manual fallback (if unsealer pod is down):**
```bash
kubectl exec -n vault vault-0 -- vault operator unseal <KEY1>
kubectl exec -n vault vault-0 -- vault operator unseal <KEY2>
```

## 5. Post-outage full cluster recovery

```bash
# 1. Restart ArgoCD
kubectl rollout restart deployment argocd-repo-server argocd-server \
  argocd-applicationset-controller argocd-notifications-controller -n argocd

# 2. Restart ESO
kubectl rollout restart deployment -n external-secrets

# 3. Verify (allow ~2 min)
kubectl get applications -n argocd -o wide
kubectl get externalsecret --all-namespaces
```

## 6. Service not accessible externally

**Checklist:**
- Ingress exists: `kubectl get ingress --all-namespaces`
- TLS cert issued: `kubectl get certificate --all-namespaces`
- DNS record points to correct IP: `dig photos.halitdincer.com`
- Port 80/443 forwarded on router to `192.168.2.216`

## 7. Atlantis not responding to PR

**Cause:** Pod crashed or GitHub webhook delivery failed.

**Fix:**
```bash
kubectl get pods -n atlantis
kubectl logs -n atlantis deploy/atlantis --tail=50
```
Check GitHub repo → Settings → Webhooks → recent deliveries for failed POSTs to `https://atlantis.halitdincer.com/events`. Re-deliver from the UI if needed.

## 8. K3s node resource pressure (pods failing to schedule)

**Cause:** Node at CPU/memory limit (K3s VM: 4 cores / 8GB RAM).

**Diagnose:**
```bash
kubectl describe node
kubectl top node
kubectl top pods --all-namespaces --sort-by=memory
```
Evict non-critical pods or resize the VM via `terraform/vms.tf` + Atlantis PR.
