# Cloudflare edge rate limiting for the iris hosts.
#
# Defense-in-depth on top of the in-app slowapi limiters:
#   - iris.halitdincer.com: 100 req/min/IP   (matches the in-app limit; edge
#     bounces obvious abuse before it hits k3s)
#   - iris-mcp.halitdincer.com: 300 req/min/IP (higher ceiling — chatty LLM
#     sessions can legitimately fan out tool calls)
#
# Phase `http_ratelimit` on a zone-kind entry-point ruleset is the v5 idiom.
# Free tier supports per-zone rate-limiting rules with `ip.src` characteristic.

resource "cloudflare_ruleset" "iris_rate_limit" {
  zone_id     = data.cloudflare_zone.halitdincer.zone_id
  name        = "iris-rate-limit"
  description = "Per-IP rate limits for iris and iris-mcp"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules = [
    {
      action      = "block"
      description = "iris.halitdincer.com — 100 req/min/IP"
      enabled     = true
      expression  = "(http.host eq \"iris.halitdincer.com\")"
      ratelimit = {
        # cf.colo.id is required by CF's API — rate counting happens per
        # datacenter, not globally. Effective limit is per-IP-per-colo,
        # which in practice tracks per-IP for any single client.
        characteristics     = ["ip.src", "cf.colo.id"]
        period              = 60
        requests_per_period = 100
        mitigation_timeout  = 60
      }
    },
    {
      action      = "block"
      description = "iris-mcp.halitdincer.com — 300 req/min/IP"
      enabled     = true
      expression  = "(http.host eq \"iris-mcp.halitdincer.com\")"
      ratelimit = {
        characteristics     = ["ip.src", "cf.colo.id"]
        period              = 60
        requests_per_period = 300
        mitigation_timeout  = 60
      }
    },
  ]
}
