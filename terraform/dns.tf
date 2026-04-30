# Namecheap registrar — delegate nameservers to Cloudflare
resource "namecheap_domain_records" "halitdincer" {
  domain = "halitdincer.com"
  mode   = "overwrite"

  nameservers = [
    "daphne.ns.cloudflare.com",
    "kellen.ns.cloudflare.com",
  ]
}

# DNS records for halitdincer.com managed via Cloudflare API.
#
# Migrated from cloudflare provider v4 (cloudflare_record) to v5
# (cloudflare_dns_record). v5 dropped cloudflare_record entirely; the schema
# is identical for simple record types but the resource type name and the
# data-source `filter` syntax changed (block → attribute).

data "cloudflare_zone" "halitdincer" {
  filter = {
    name = "halitdincer.com"
  }
}

# ── Import blocks ────────────────────────────────────────────────────────────
# Atlantis pod has no terraform state for this repo, so the first apply must
# *adopt* the records that already exist in Cloudflare instead of trying to
# re-create them. Block ID format: "<zone_id>/<dns_record_id>".
#
# Six record blocks below (argocd, prometheus, loki, proxmox, www, dkim)
# intentionally have no import block — they are declared in dns.tf but were
# never applied; Atlantis will *create* them on first apply. Confirmed by:
#   curl https://api.cloudflare.com/client/v4/zones/<zone>/dns_records
# returning 9 records, missing those 6.
#
# After Atlantis's first successful apply, the import blocks become no-ops
# and a follow-up PR can delete them.

import {
  to = cloudflare_dns_record.wildcard
  id = "${data.cloudflare_zone.halitdincer.zone_id}/098c6102da4cb48094fd9497816ed945"
}
import {
  to = cloudflare_dns_record.grafana
  id = "${data.cloudflare_zone.halitdincer.zone_id}/2d36cabaf6ff17d4a71d98b60766f488"
}
import {
  to = cloudflare_dns_record.vault
  id = "${data.cloudflare_zone.halitdincer.zone_id}/8321dfca85cbf0e29b3ebd3bfdca8521"
}
import {
  to = cloudflare_dns_record.mx1
  id = "${data.cloudflare_zone.halitdincer.zone_id}/8d3922cc9c88466119562ff0aa8b4cd5"
}
import {
  to = cloudflare_dns_record.mx2
  id = "${data.cloudflare_zone.halitdincer.zone_id}/4c3a89e2079eed28c596074db9a105ba"
}
import {
  to = cloudflare_dns_record.apple_domain_verification
  id = "${data.cloudflare_zone.halitdincer.zone_id}/89565740f741eb3acce9d79de3ac3cb6"
}
import {
  to = cloudflare_dns_record.spf
  id = "${data.cloudflare_zone.halitdincer.zone_id}/25b1a88b4793ffa08886ecc0fdd733e0"
}
import {
  to = cloudflare_dns_record.dmarc
  id = "${data.cloudflare_zone.halitdincer.zone_id}/bf25abfd2e9d7d6141179356bfe0ae8f"
}

# ── Homeserver routing ──

# Wildcard CNAME - routes all subdomains through Cloudflare Tunnel to home server
# K3s nginx ingress handles routing to individual services
resource "cloudflare_dns_record" "wildcard" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "*"
  type    = "CNAME"
  content = "57db95ef-dc2a-4de3-be87-f5f83cf83f86.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

# ── Private K3s services - Tailscale-only access ──

resource "cloudflare_dns_record" "argocd" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "argocd"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_dns_record" "grafana" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "grafana"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_dns_record" "prometheus" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "prometheus"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_dns_record" "loki" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "loki"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_dns_record" "vault" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "vault"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_dns_record" "proxmox" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "proxmox"
  type    = "A"
  content = "100.112.34.54"
  ttl     = 1800
  proxied = false
}

resource "cloudflare_dns_record" "www" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "www"
  type    = "CNAME"
  content = "57db95ef-dc2a-4de3-be87-f5f83cf83f86.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

# ── iCloud Mail ──

resource "cloudflare_dns_record" "mx1" {
  zone_id  = data.cloudflare_zone.halitdincer.zone_id
  name     = "@"
  type     = "MX"
  content  = "mx01.mail.icloud.com"
  priority = 10
  ttl      = 1800
  proxied  = false
}

resource "cloudflare_dns_record" "mx2" {
  zone_id  = data.cloudflare_zone.halitdincer.zone_id
  name     = "@"
  type     = "MX"
  content  = "mx02.mail.icloud.com"
  priority = 10
  ttl      = 1800
  proxied  = false
}

# Apple domain verification
resource "cloudflare_dns_record" "apple_domain_verification" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "@"
  type    = "TXT"
  content = "apple-domain=p5WQ6nkIG4sBs3xx"
  ttl     = 1800
  proxied = false
}

# SPF - authorize iCloud to send mail for this domain
resource "cloudflare_dns_record" "spf" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 include:icloud.com ~all"
  ttl     = 1800
  proxied = false
}

# DKIM - iCloud mail signing
resource "cloudflare_dns_record" "dkim" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "sig1._domainkey"
  type    = "CNAME"
  content = "sig1.dkim.halitdincer.com.at.icloudmailadmin.com"
  ttl     = 1800
  proxied = false
}

# DMARC - reject unauthenticated mail
resource "cloudflare_dns_record" "dmarc" {
  zone_id = data.cloudflare_zone.halitdincer.zone_id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=reject"
  ttl     = 1800
  proxied = false
}
