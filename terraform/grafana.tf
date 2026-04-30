# Grafana Cloud — dashboards + alerts + ntfy contact point.
#
# Auth: var.grafana_auth_token is a Service Account token created once in the
# Cloud Grafana UI (Administration → Service accounts) with Admin scope. The
# token + stack URL are injected as TF_VAR_grafana_url / TF_VAR_grafana_auth_token
# from the atlantis-env Secret (synced from Vault key secret/atlantis/config).
#
# Datasources are *read*, not created — Cloud Grafana auto-provisions Mimir/Loki
# datasources on stack creation. We just look up their UIDs to wire them into
# dashboards and alert rules.

# ── Datasource lookups ────────────────────────────────────────────────────────

data "grafana_data_source" "mimir" {
  name = var.grafana_mimir_datasource_name
}

data "grafana_data_source" "loki" {
  name = var.grafana_loki_datasource_name
}

# ── Folder ────────────────────────────────────────────────────────────────────

resource "grafana_folder" "homeserver" {
  title = "homeserver"
}

# ── Dashboards ────────────────────────────────────────────────────────────────
# JSON files are the original repo dashboards. The hardcoded "prometheus" and
# "loki" datasource UIDs in the JSON get rewritten to the real Cloud UIDs at
# apply time so the dashboards actually render data.

locals {
  dashboard_json_files = {
    homeserver-overview = "${path.module}/grafana-dashboards/homeserver-overview.json"
    homeserver-logs     = "${path.module}/grafana-dashboards/homeserver-logs.json"
    argocd              = "${path.module}/grafana-dashboards/argocd.json"
  }
}

resource "grafana_dashboard" "homeserver" {
  for_each  = local.dashboard_json_files
  folder    = grafana_folder.homeserver.uid
  overwrite = true

  config_json = replace(
    replace(
      file(each.value),
      "\"uid\": \"prometheus\"",
      "\"uid\": \"${data.grafana_data_source.mimir.uid}\""
    ),
    "\"uid\": \"loki\"",
    "\"uid\": \"${data.grafana_data_source.loki.uid}\""
  )
}

# ── Alerting: contact point (ntfy webhook) ────────────────────────────────────
# Replaces the in-cluster ntfy-relay. Cloud Grafana POSTs JSON directly to
# ntfy.sh, with topic + priority computed per alert in the body template.

resource "grafana_contact_point" "ntfy" {
  name = "ntfy"

  webhook {
    url                     = "https://ntfy.sh"
    http_method             = "POST"
    disable_resolve_message = false
    message = jsonencode({
      topic    = var.ntfy_topic
      title    = "[{{ .Status | toUpper }}] {{ (index .Alerts 0).Labels.alertname }}"
      message  = "{{ range .Alerts }}{{ .Annotations.summary }}{{ if .Annotations.description }}\n{{ .Annotations.description }}{{ end }}\nseverity: {{ .Labels.severity }}\n{{ end }}"
      priority = "{{ if eq .Status \"resolved\" }}3{{ else if eq (index .Alerts 0).Labels.severity \"critical\" }}5{{ else }}4{{ end }}"
    })
  }
}

# ── Alerting: notification policy ─────────────────────────────────────────────
# Default route → ntfy. No child policies (single contact point covers all).

resource "grafana_notification_policy" "root" {
  contact_point = grafana_contact_point.ntfy.name
  group_by      = ["alertname", "severity"]

  group_wait      = "30s"
  group_interval  = "5m"
  repeat_interval = "4h"
}

# ── Alerting: critical alert rules ────────────────────────────────────────────
# Ported from the old PrometheusRule (k3s-manifests/apps/monitoring/templates/
# prometheusrule-critical.yaml). Uses Grafana's three-stage data pipeline:
#   A: instant PromQL query against Mimir
#   B: reduce A to a single value (last)
#   C: threshold check on B → boolean condition that fires the alert
#
# Note on label scheme: Alloy now scrapes Proxmox host with job="node",
# instance="proxmox" (was job="proxmox-host" in the old kube-prometheus-stack
# additionalScrapeConfig). The ProxmoxHostDown expr below matches the new labels.

locals {
  # Reusable B-stage (reduce) and C-stage (threshold) data blocks.
  # Each alert defines its own A-stage (the PromQL).
  expr_reduce = jsonencode({
    conditions = [{
      evaluator = { params = [], type = "gt" }
      operator  = { type = "and" }
      query     = { params = ["B"] }
      reducer   = { params = [], type = "last" }
      type      = "query"
    }]
    datasource    = { name = "Expression", type = "__expr__", uid = "__expr__" }
    expression    = "A"
    intervalMs    = 1000
    maxDataPoints = 43200
    reducer       = "last"
    refId         = "B"
    type          = "reduce"
  })
}

resource "grafana_rule_group" "critical" {
  name             = "critical"
  folder_uid       = grafana_folder.homeserver.uid
  interval_seconds = 60

  # ── DiskFull ──
  rule {
    name      = "DiskFull"
    for       = "10m"
    condition = "C"

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.mimir.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "prometheus", uid = data.grafana_data_source.mimir.uid }
        expr       = "(1 - node_filesystem_avail_bytes{fstype!=\"tmpfs\",mountpoint=\"/\"} / node_filesystem_size_bytes) * 100"
        instant    = true
        refId      = "A"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = local.expr_reduce
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        conditions = [{
          evaluator = { params = [95], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["C"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
        datasource = { name = "Expression", type = "__expr__", uid = "__expr__" }
        expression = "B"
        refId      = "C"
        type       = "threshold"
      })
    }

    labels = {
      severity = "critical"
    }
    annotations = {
      summary     = "Disk almost full"
      description = "{{ $labels.instance }} root filesystem >95% full."
    }
  }

  # ── MemoryCritical ──
  rule {
    name      = "MemoryCritical"
    for       = "5m"
    condition = "C"

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.mimir.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "prometheus", uid = data.grafana_data_source.mimir.uid }
        expr       = "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100"
        instant    = true
        refId      = "A"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = local.expr_reduce
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        conditions = [{
          evaluator = { params = [95], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["C"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
        datasource = { name = "Expression", type = "__expr__", uid = "__expr__" }
        expression = "B"
        refId      = "C"
        type       = "threshold"
      })
    }

    labels = {
      severity = "critical"
    }
    annotations = {
      summary     = "Memory almost exhausted"
      description = "{{ $labels.instance }} memory usage >95%."
    }
  }

  # ── ProxmoxHostDown ──
  rule {
    name      = "ProxmoxHostDown"
    for       = "5m"
    condition = "C"

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.mimir.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "prometheus", uid = data.grafana_data_source.mimir.uid }
        expr       = "up{job=\"node\",instance=\"proxmox\"}"
        instant    = true
        refId      = "A"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = local.expr_reduce
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      # Fires when up == 0 (host down or scrape failing).
      model = jsonencode({
        conditions = [{
          evaluator = { params = [1], type = "lt" }
          operator  = { type = "and" }
          query     = { params = ["C"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
        datasource = { name = "Expression", type = "__expr__", uid = "__expr__" }
        expression = "B"
        refId      = "C"
        type       = "threshold"
      })
    }

    labels = {
      severity = "critical"
    }
    annotations = {
      summary     = "Proxmox host unreachable"
      description = "Proxmox node_exporter at 10.10.10.1:9100 not responding."
    }
  }
}
