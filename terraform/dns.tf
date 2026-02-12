# DNS records for halitdincer.com managed via Namecheap API
#
# Note: The Namecheap provider has rate-limiting issues with frequent
# terraform plan/apply. This is acceptable for a small, static record set.
# No-IP DDNS (halitdincer.ddns.net) continues to handle dynamic IP updates.

resource "namecheap_domain_records" "halitdincer" {
  domain     = "halitdincer.com"
  mode       = "OVERWRITE"
  email_type = "MX"

  # ── Homeserver routing ──

  # Wildcard CNAME - routes all subdomains through DDNS to home server
  # K3s nginx ingress handles routing to individual services
  record {
    hostname = "*"
    type     = "CNAME"
    address  = "halitdincer.ddns.net."
    ttl      = 1800
  }

  # ── OpenClaw instances - Tailscale-only access (static Tailscale IP) ──

  record {
    hostname = "openclaw"
    type     = "A"
    address  = "100.82.144.118"
    ttl      = 1800
  }

  record {
    hostname = "openclaw-house"
    type     = "A"
    address  = "100.82.144.118"
    ttl      = 1800
  }

  # ── Private K3s services - Tailscale-only access ──

  record {
    hostname = "argocd"
    type     = "A"
    address  = "100.112.34.54"
    ttl      = 1800
  }

  record {
    hostname = "grafana"
    type     = "A"
    address  = "100.112.34.54"
    ttl      = 1800
  }

  record {
    hostname = "prometheus"
    type     = "A"
    address  = "100.112.34.54"
    ttl      = 1800
  }

  record {
    hostname = "vault"
    type     = "A"
    address  = "100.112.34.54"
    ttl      = 1800
  }

  record {
    hostname = "www"
    type     = "CNAME"
    address  = "halitdincer.ddns.net."
    ttl      = 1800
  }

  # ── iCloud Mail ──

  record {
    hostname = "@"
    type     = "MX"
    address  = "mx01.mail.icloud.com."
    mx_pref  = 10
    ttl      = 1800
  }

  record {
    hostname = "@"
    type     = "MX"
    address  = "mx02.mail.icloud.com."
    mx_pref  = 10
    ttl      = 1800
  }

  # Apple domain verification
  record {
    hostname = "@"
    type     = "TXT"
    address  = "apple-domain=p5WQ6nkIG4sBs3xx"
    ttl      = 1800
  }

  # SPF - authorize iCloud to send mail for this domain
  record {
    hostname = "@"
    type     = "TXT"
    address  = "v=spf1 include:icloud.com ~all"
    ttl      = 1800
  }

  # DKIM - iCloud mail signing
  record {
    hostname = "sig1._domainkey"
    type     = "CNAME"
    address  = "sig1.dkim.halitdincer.com.at.icloudmailadmin.com."
    ttl      = 1800
  }

  # DMARC - reject unauthenticated mail
  record {
    hostname = "_dmarc"
    type     = "TXT"
    address  = "v=DMARC1; p=reject"
    ttl      = 1800
  }
}
