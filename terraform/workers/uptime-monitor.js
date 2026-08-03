/**
 * Independent uptime monitor for the public *.halitdincer.com services.
 *
 * Runs on Cloudflare's edge (NOT the homeserver), so it keeps checking and
 * alerting precisely when the homeserver is down — the failure mode where the
 * on-box Gatus monitor also died and never paged anyone.
 *
 * Behaviour:
 *  - scheduled() runs on the cron trigger (every minute) and checks each endpoint
 *    through the Cloudflare tunnel.
 *  - "down" = HTTP 5xx (502/504/520-527/530 are Cloudflare origin/tunnel errors)
 *    or a fetch error/timeout. Anything <500 (200/301/302/401/403) = "up".
 *  - State lives in Workers KV (env.STATE) so we only page on TRANSITIONS: a DOWN
 *    alert after FAIL_THRESHOLD consecutive failures (rides out transient blips
 *    like a brief ISP hiccup), and a RECOVERED alert when it comes back. No spam.
 *  - Alerts POST to ntfy at https://ntfy.sh/${NTFY_TOPIC} (same channel Grafana
 *    already uses).
 *  - GET the worker URL for an on-demand, read-only status check (no state writes,
 *    no notifications) — handy for eyeballing.
 *
 * Only PUBLIC (tunnel-routed) hostnames are listed. Tailscale-only services
 * (argocd/grafana/vault/proxmox) are unreachable from Cloudflare's edge and would
 * false-alarm, so they are intentionally excluded.
 */

const ENDPOINTS = [
  { name: "Immich (photos)", url: "https://photos.halitdincer.com/" },
  { name: "Homepage", url: "https://home.halitdincer.com/" },
  { name: "Home Assistant", url: "https://ha.halitdincer.com/" },
  { name: "Flight Tracker", url: "https://flights.halitdincer.com/" },
  { name: "job-scout", url: "https://jobs.halitdincer.com/" },
  { name: "Coder", url: "https://code.halitdincer.com/" },
];

const FAIL_THRESHOLD = 2; // consecutive fails before paging (~2 min at 1/min)
const TIMEOUT_MS = 15000;

async function checkOne(ep) {
  try {
    const res = await fetch(ep.url, {
      method: "GET",
      redirect: "manual",
      cache: "no-store",
      signal: AbortSignal.timeout(TIMEOUT_MS),
      headers: { "user-agent": "halitdincer-uptime-monitor/1 (cloudflare-worker)" },
    });
    // 5xx == origin/tunnel down; <500 (incl. auth redirects/401) == responding.
    return { up: res.status < 500, status: res.status };
  } catch (err) {
    return { up: false, status: 0, error: String((err && err.name) || err) };
  }
}

async function notify(env, { title, message, priority, tags }) {
  if (!env.NTFY_TOPIC) return;
  const base = env.NTFY_URL || "https://ntfy.sh";
  try {
    await fetch(`${base}/${env.NTFY_TOPIC}`, {
      method: "POST",
      body: message,
      headers: { Title: title, Priority: priority, Tags: tags },
    });
  } catch (_) {
    // best effort — never let a notification failure break the run
  }
}

async function evaluate(env, ep) {
  const key = `state:${ep.name}`;
  const prev = (await env.STATE.get(key, "json")) || { fails: 0, alerted: false };
  const result = await checkOne(ep);

  if (result.up) {
    if (prev.alerted) {
      await notify(env, {
        title: `✅ ${ep.name} recovered`,
        message: `${ep.url} is back up (HTTP ${result.status}).`,
        priority: "default",
        tags: "white_check_mark",
      });
    }
    await env.STATE.put(key, JSON.stringify({ fails: 0, alerted: false }));
  } else {
    const fails = prev.fails + 1;
    let alerted = prev.alerted;
    if (fails >= FAIL_THRESHOLD && !prev.alerted) {
      const detail = result.error ? `${result.error}` : `HTTP ${result.status}`;
      await notify(env, {
        title: `🔴 ${ep.name} is DOWN`,
        message: `${ep.url} failed ${fails} consecutive checks (${detail}).`,
        priority: "urgent",
        tags: "rotating_light",
      });
      alerted = true;
    }
    await env.STATE.put(key, JSON.stringify({ fails, alerted }));
  }

  return { name: ep.name, url: ep.url, ...result };
}

export default {
  async scheduled(event, env, ctx) {
    ctx.waitUntil(Promise.all(ENDPOINTS.map((ep) => evaluate(env, ep))));
  },

  async fetch(request, env) {
    // Read-only: check + report, but do NOT mutate state or send notifications.
    const results = await Promise.all(
      ENDPOINTS.map(async (ep) => ({ name: ep.name, url: ep.url, ...(await checkOne(ep)) }))
    );
    const anyDown = results.some((r) => !r.up);
    return new Response(
      JSON.stringify({ checkedAt: new Date().toISOString(), anyDown, results }, null, 2),
      { status: anyDown ? 503 : 200, headers: { "content-type": "application/json" } }
    );
  },
};
