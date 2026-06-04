# Cloudflare edge rate limiting for the iris hosts.
#
# Cloudflare Free allows ONE rate-limiting rule per zone, so this is a single
# rule covering both iris hosts with a permissive ceiling. The in-app slowapi
# limiters still enforce tighter per-host caps at L7 (iris: 100/min,
# iris-mcp: 60/min); this edge rule exists to absorb gross abuse before it
# reaches k3s.
#
#   - Both hosts:       300 req/min per IP per CF colo
#   - Block timeout:    60s
#
# Per CF API, ratelimit characteristics MUST include cf.colo.id (counting is
# processed at each datacenter, not globally). Effective behavior is per-IP
# per-colo, which is essentially per-IP for any one real client.

resource "cloudflare_ruleset" "iris_rate_limit" {
  zone_id     = data.cloudflare_zone.halitdincer.zone_id
  name        = "iris-rate-limit"
  description = "Per-IP rate limit for iris + iris-mcp"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules = [
    {
      action      = "block"
      description = "iris + iris-mcp — 300 req/min/IP per colo"
      enabled     = true
      expression  = "(http.host eq \"iris.halitdincer.com\" or http.host eq \"iris-mcp.halitdincer.com\")"
      ratelimit = {
        characteristics     = ["ip.src", "cf.colo.id"]
        period              = 60
        requests_per_period = 300
        mitigation_timeout  = 60
      }
    },
  ]
}
