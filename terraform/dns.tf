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
# Each Cloudflare record was created out-of-band (or with a since-lost local
# state file), so the first Atlantis apply needs to *adopt* the existing
# records into state, not re-create them. Import block IDs are
# `<zone_id>/<record_id>` — fill the record IDs by running, locally:
#
#   ZONE=$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
#     "https://api.cloudflare.com/client/v4/zones?name=halitdincer.com" \
#     | jq -r '.result[0].id')
#   curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
#     "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records?per_page=100" \
#     | jq -r '.result[] | "\(.name) \(.type) \(.id)"'
#
# Then paste the IDs into the placeholders below. After Atlantis applies once,
# the import blocks become no-ops and can be deleted in a follow-up PR.
#
# Format: id = "<zone_id>/<record_id>"

import {
  to = cloudflare_dns_record.wildcard
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.argocd
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.grafana
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.prometheus
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.loki
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.vault
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.proxmox
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.www
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.mx1
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.mx2
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.apple_domain_verification
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.spf
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.dkim
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
}
import {
  to = cloudflare_dns_record.dmarc
  id = "${data.cloudflare_zone.halitdincer.zone_id}/REPLACE_WITH_RECORD_ID"
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
