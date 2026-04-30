# Network

## Topology

| Layer | Detail |
|-------|--------|
| Proxmox host | WiFi (`wlp3s0`) gets DHCP from home router; `vmbr0` at `10.10.10.1/24` (`bridge-ports none`) |
| VM subnet | `10.10.10.0/24` via `vmbr0`, DHCP from dnsmasq |
| NAT | nftables MASQUERADE out `wlp3s0`/`nic0` for `10.10.10.0/24` |
| Pod route | `10.42.0.0/16` via `10.10.10.105` (post-up in `/etc/network/interfaces`) |

## DHCP Assignments (dnsmasq)

| VMID | IP | Hostname |
|------|----|----------|
| 100 | 10.10.10.100 | immich |
| 103 | 10.10.10.103 | haos |
| 105 | 10.10.10.105 | k3s |
| 106 | 10.10.10.106 | devbox |

## Public Access -- Cloudflare Tunnel

| Field | Value |
|-------|-------|
| Tunnel ID | `57db95ef-dc2a-4de3-be87-f5f83cf83f86` |
| Connector | `cloudflared` on Proxmox host (systemd service) |
| Wildcard route | `*.halitdincer.com` -> `http://10.10.10.105` (K3s nginx ingress) |
| DNS | CNAME `*` -> `<tunnel-id>.cfargotunnel.com` (proxied) |

## Private Access -- Tailscale

K3s Tailscale IP: `100.112.34.54`

| Subdomain | Type | Proxied | Access |
|-----------|------|---------|--------|
| argocd | A -> 100.112.34.54 | No | Tailscale only |
| vault | A -> 100.112.34.54 | No | Tailscale only |
| proxmox | A -> 100.112.34.54 | No | Tailscale only |

Grafana / Prometheus / Loki are no longer hosted in-cluster — observability
moved to Grafana Cloud. Cloud Grafana is reached at the stack URL on
`*.grafana.net` (public, account-gated). No DNS records under
`halitdincer.com` for these services.

## DNS Chain

Namecheap (registrar) -> Cloudflare NS (`daphne` + `kellen`) -> Cloudflare DNS records (managed by Terraform in `terraform/dns.tf`)

## Ingress Routing

nginx-ingress on K3s (`10.10.10.105:80/443`) handles both tunnel and Tailscale traffic. ConfigMap sets `use-forwarded-headers: "true"` to trust Cloudflare's `X-Forwarded-Proto` (prevents redirect loops).

## TLS Certificates

Single wildcard cert `*.halitdincer.com` (+ apex) covers every public subdomain. Issued by Let's Encrypt via cert-manager using **Cloudflare DNS-01**.

| Component | Detail |
|-----------|--------|
| Certificate | `wildcard-halitdincer` in `ingress-nginx` namespace -> Secret `wildcard-halitdincer-tls` |
| ClusterIssuer | `letsencrypt-prod-dns01` (DNS-01 solver, Cloudflare provider) |
| Cloudflare API token | Vault `secret/cert-manager/config` -> ESO -> Secret `cloudflare-api-token` in `cert-manager` ns. Scope: `Zone:DNS:Edit` + `Zone:Zone:Read` on `halitdincer.com` only |
| Default cert | nginx-ingress controller arg `--default-ssl-certificate=ingress-nginx/wildcard-halitdincer-tls` makes the wildcard the fallback for every host |
| Renewal | Auto, 15 days before expiry (90-day cert) |

Adding a new subdomain: just create the Ingress with `host: foo.halitdincer.com`. No `cert-manager.io/cluster-issuer` annotation, no `spec.tls` block — wildcard is inherited automatically.

## Network Recovery (auto-failover)

Connection priority: LAN (`nic0`, metric 100) > WiFi (`wlp3s0`, metric 200) > Recovery

| Layer | Trigger | Action |
|-------|---------|--------|
| Watchdog | Both interfaces down for 2 min | Restore known-good config, restart networking |
| Hardware watchdog | Kernel hang >30s | Auto-reboot (services start normally) |
| hostapd AP | 3 failed recovery cycles (~15 min) | WiFi becomes AP: SSID `proxmox-recovery`, SSH at `192.168.4.1` |

Deploy: `ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/network-recovery.yml`
Logs: `journalctl -t network-watchdog -f`
