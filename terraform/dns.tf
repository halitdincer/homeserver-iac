# Namecheap registrar — delegate nameservers to Cloudflare
resource "namecheap_domain_records" "halitdincer" {
  domain = "halitdincer.com"
  mode   = "overwrite"

  nameservers = [
    "daphne.ns.cloudflare.com",
    "kellen.ns.cloudflare.com",
  ]
}

# DNS records for halitdincer.com managed via Cloudflare API

data "cloudflare_zone" "halitdincer" {
  filter {
    name = "halitdincer.com"
  }
}

# ── Homeserver routing ──

# Wildcard CNAME - routes all subdomains through Cloudflare Tunnel to home server
# K3s nginx ingress handles routing to individual services
resource "cloudflare_record" "wildcard" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "*"
  type    = "CNAME"
  content = "57db95ef-dc2a-4de3-be87-f5f83cf83f86.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

# ── Private K3s services - Tailscale-only access ──

resource "cloudflare_record" "argocd" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "argocd"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_record" "grafana" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "grafana"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_record" "prometheus" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "prometheus"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_record" "vault" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "vault"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_record" "proxmox" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "proxmox"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "www"
  type    = "CNAME"
  content = "57db95ef-dc2a-4de3-be87-f5f83cf83f86.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

# ── iCloud Mail ──

resource "cloudflare_record" "mx1" {
  zone_id  = data.cloudflare_zone.halitdincer.zone_id
  name     = "@"
  type     = "MX"
  content  = "mx01.mail.icloud.com"
  priority = 10
  ttl      = 1800
  proxied  = false
}

resource "cloudflare_record" "mx2" {
  zone_id  = data.cloudflare_zone.halitdincer.zone_id
  name     = "@"
  type     = "MX"
  content  = "mx02.mail.icloud.com"
  priority = 10
  ttl      = 1800
  proxied  = false
}

# Apple domain verification
resource "cloudflare_record" "apple_domain_verification" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "@"
  type    = "TXT"
  content = "apple-domain=p5WQ6nkIG4sBs3xx"
  ttl     = 1800
  proxied = false
}

# SPF - authorize iCloud to send mail for this domain
resource "cloudflare_record" "spf" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 include:icloud.com ~all"
  ttl     = 1800
  proxied = false
}

# DKIM - iCloud mail signing
resource "cloudflare_record" "dkim" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "sig1._domainkey"
  type    = "CNAME"
  content = "sig1.dkim.halitdincer.com.at.icloudmailadmin.com"
  ttl     = 1800
  proxied = false
}

# DMARC - reject unauthenticated mail
resource "cloudflare_record" "dmarc" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=reject"
  ttl     = 1800
  proxied = false
}
