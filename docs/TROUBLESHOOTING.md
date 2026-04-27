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

**Automated:** `vault-unsealer` pod handles this automatically:
1. Unsealer container detects sealed Vault, submits unseal keys (~30s)
2. Recovery container detects unseal, waits for readiness, restarts ArgoCD + ESO

**Verify automated recovery worked:**
```bash
kubectl get applications -n argocd -o wide
kubectl get externalsecret --all-namespaces
kubectl logs deployment/vault-unsealer -n vault -c recovery --tail=20
```

**Manual fallback (if vault-unsealer pod is down):**
```bash
kubectl rollout restart deployment argocd-repo-server argocd-server \
  argocd-applicationset-controller argocd-notifications-controller -n argocd
kubectl rollout restart deployment -n external-secrets
```

## 6. Service not accessible externally

**Checklist:**
- Ingress exists: `kubectl get ingress --all-namespaces`
- Wildcard cert healthy: `kubectl get certificate -n ingress-nginx wildcard-halitdincer` (READY=True)
- DNS record points to correct IP: `dig photos.halitdincer.com`
- Public access via Cloudflare Tunnel (no port forwarding needed)

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

## 9. Cloudflare Tunnel down (all public services 502/522)

**Cause:** `cloudflared` service on Proxmox host stopped or lost connectivity.

**Fix:**
```bash
ssh root@10.10.10.1 "systemctl status cloudflared"
ssh root@10.10.10.1 "systemctl restart cloudflared"
# Verify: curl -I https://home.halitdincer.com (expect 200)
```

## 10. WiFi lost on Proxmox host (all VMs lose internet)

**Cause:** wpa_supplicant crashed or WiFi AP restarted. VMs stay up but have no NAT path out.

**CRITICAL:** Never use `ifreload -a` to restore — it kills the bridge and drops all VM connectivity.

**Automated recovery:** The network watchdog (`network-watchdog.timer`) handles this automatically:
- Detects failure within 2 min, restores known-good config
- If 3 recovery attempts fail, switches WiFi to AP mode (SSID: `proxmox-recovery`)
- Check logs: `journalctl -t network-watchdog -f`

**Manual fix (if watchdog hasn't recovered yet):**
```bash
# From Tailscale (if still up) or physical console:
ip link set wlp3s0 up
wpa_supplicant -B -i wlp3s0 -c /etc/wpa_supplicant/wpa_supplicant.conf
dhclient wlp3s0
# Verify: ping 1.1.1.1 from host AND from a VM
```

**If in AP recovery mode:**
```bash
# Connect to "proxmox-recovery" WiFi, then:
ssh root@192.168.4.1
/usr/local/sbin/restore-normal-network.sh
```
