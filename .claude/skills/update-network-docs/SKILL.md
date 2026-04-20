---
name: update-network-docs
description: Update docs/NETWORK.md when networking, DNS, ingress, or tunnel config changes.
---

# Update Network Documentation

Update `docs/NETWORK.md` to reflect changes in networking, DNS, ingress, or tunnel configuration.

## When to Run

After changes to:
- `terraform/dns.tf` (DNS records, zone config)
- `k3s-manifests/ingresses/` (ingress resources)
- Cloudflare Tunnel config (cloudflared service)
- Tailscale configuration
- Network topology (NAT rules, dnsmasq, interfaces)

## Sections to Check

1. **Topology table** — VM subnet, NAT, pod route
2. **DHCP Assignments** — VM IPs and hostnames (cross-check with `terraform/vms.tf`)
3. **Cloudflare Tunnel** — tunnel ID, wildcard route, connector location
4. **Tailscale table** — private DNS records (A records pointing to 100.x.x.x)
5. **DNS Chain** — registrar → NS → records source
6. **Ingress Routing** — nginx config, forwarded headers

## Rules

- Keep under 2KB total
- Use tables for IP/DNS/record data
- Only document what exists in code — no speculative entries
- If a new Tailscale-only subdomain is added in `terraform/dns.tf`, add it to the Private Access table
- If a new public ingress is added, note that it routes through the existing wildcard CNAME
