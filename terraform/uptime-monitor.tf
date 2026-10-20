# Independent uptime monitor — a Cloudflare Worker on a cron trigger that checks
# the public *.halitdincer.com services from Cloudflare's EDGE and pushes to ntfy
# on failure. It lives OFF the homeserver, so it still alerts when the homeserver
# is down — the exact failure mode where the on-box Gatus monitor died silently
# (2026-08-03 outage). See terraform/workers/uptime-monitor.js for the logic.
#
# Reachability: only PUBLIC (tunnel-routed) hostnames are monitored. The
# Tailscale-only services (argocd/grafana/vault/proxmox — A records to the
# Tailscale IP) are unreachable from Cloudflare's edge and would false-alarm.
#
# ⚠️ API TOKEN SCOPES: var.cloudflare_api_token must include, in addition to DNS:
#   - Account » Workers Scripts : Edit
#   - Account » Workers KV Storage : Edit
# Without these the apply fails with a 403. (DNS-only token is not enough.)

variable "cloudflare_account_id" {
  description = "Cloudflare account ID for Workers. Defaults to the account that owns the halitdincer.com zone."
  type        = string
  default     = ""
}

locals {
  # Prefer an explicit override; otherwise use the account that owns the zone.
  cf_account_id = var.cloudflare_account_id != "" ? var.cloudflare_account_id : data.cloudflare_zone.halitdincer.account.id
}

# KV namespace for per-endpoint state (transition-based alerting / de-dup).
resource "cloudflare_workers_kv_namespace" "uptime_state" {
  account_id = local.cf_account_id
  title      = "uptime-monitor-state"
}

# The Worker script (ES module).
resource "cloudflare_workers_script" "uptime_monitor" {
  account_id         = local.cf_account_id
  script_name        = "uptime-monitor"
  content            = file("${path.module}/workers/uptime-monitor.js")
  main_module        = "uptime-monitor.js"
  compatibility_date = "2025-06-01"

  bindings = [
    {
      name         = "STATE"
      type         = "kv_namespace"
      namespace_id = cloudflare_workers_kv_namespace.uptime_state.id
    },
    {
      name = "NTFY_TOPIC"
      type = "plain_text"
      text = var.ntfy_topic
    },
  ]
}

# Cron trigger — run every 30 minutes. The worker does one KV put per endpoint
# per run, and the free plan caps KV at 1,000 puts/day: every minute (6 × 1440 =
# 8,640/day) blew the cap ~3h into each UTC day, after which state writes failed.
# Every 30 min = 6 × 48 = 288/day. With FAIL_THRESHOLD=2, a real outage pages
# after ~30-60 minutes.
resource "cloudflare_workers_cron_trigger" "uptime_monitor" {
  account_id  = local.cf_account_id
  script_name = cloudflare_workers_script.uptime_monitor.script_name
  schedules = [{
    cron = "*/30 * * * *"
  }]
}

output "uptime_monitor_script" {
  description = "Name of the deployed uptime-monitor Worker script"
  value       = cloudflare_workers_script.uptime_monitor.script_name
}
