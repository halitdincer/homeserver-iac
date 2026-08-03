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

# Cron trigger — run every minute. With FAIL_THRESHOLD=2 in the worker, a real
# outage pages after ~2 minutes (rides out single transient blips).
resource "cloudflare_workers_cron_trigger" "uptime_monitor" {
  account_id  = local.cf_account_id
  script_name = cloudflare_workers_script.uptime_monitor.script_name
  schedules = [{
    cron = "* * * * *"
  }]
}

output "uptime_monitor_script" {
  description = "Name of the deployed uptime-monitor Worker script"
  value       = cloudflare_workers_script.uptime_monitor.script_name
}
