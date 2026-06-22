# Runbook — Memory leak → OOMKilled / restart loop

> **Audience**: SRE, Support
> **Last verified**: June 2026
> **Severity**: 2
> **Service**: `commerce` · **Namespace**: `commerce`
> **Primary alert**: `commerce-oomkilled` (Azure Monitor scheduled query)
> **Context**: This runbook is referenced from the [SAP MOOC on Edge Integration Cell with AKS](https://learning.sap.com). It uses a sample `commerce` application to demonstrate how Azure SRE Agent can diagnose and remediate a memory-leak scenario on AKS.

---

## Symptoms

- Alert `commerce-oomkilled` fires (Sev 2).
- `Deployment/commerce` pod is in a restart loop; restart count climbs.
- Container `lastState.terminated.reason = OOMKilled`, `exitCode = 137`.
- Pod memory ramps from a ~430 MiB idle baseline up to the **768 MiB** limit, then the container is killed and restarts at low memory.
- Intermittent HTTP 5xx / connection errors while the pod is restarting; startup-probe `connection refused` events.

---

## Detection

- **Alert:** `commerce-oomkilled` — align with the monitoring guidance in [`operations.md`](operations.md#monitoring).
- **KQL (OOMKilled):** use the **Key Log Queries (KQL)** section in [`operations.md`](operations.md#key-log-queries-kql) as the baseline and adapt for this alert.
- **Live confirmation:**

```bash
# Check pod status and restart count
kubectl get pods -n commerce -o wide

# Confirm OOMKilled as the termination reason
kubectl get pod -n commerce -l app=commerce \
  -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.reason}{" exit="}{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'

# Check current memory consumption
kubectl top pod -n commerce
```

Expected during the incident: `reason=OOMKilled exit=137`, restart count > 0 and increasing, memory near 768Mi just before a kill.

---

## Root Cause

`CatalogService` caches rendered search results in an **unbounded in-memory map keyed on the raw query string** (`/catalog/search?q=...`). The map has **no eviction** when the configuration `commerce.search-cache-max-size` (env `SEARCH_CACHE_MAX_SIZE`) is `0` or unset — which is the current/default state.

| Factor | Detail |
|--------|--------|
| Cache key | Raw query string (`q` parameter value) |
| Eviction policy | **None** when `SEARCH_CACHE_MAX_SIZE` is `0` or unset |
| Trigger | High-cardinality query traffic (many unique `q` values) |
| Growth pattern | Linear with distinct query count; heap grows until 768 MiB limit |
| Self-recovery | Yes — when unique-query traffic stops, no new entries; pod recovers after restart |

- The cache only grows with **distinct** query strings. Normal low-cardinality traffic is harmless.
- Under traffic with many unique `q` values (e.g., a load generator, a crawler, or cache-busting query parameters), each distinct query retains its own freshly rendered result list forever.
- Heap grows with query cardinality until the pod exceeds its 768 MiB limit and is **OOMKilled**.
- It is **traffic-driven, not a feature flag**: when the unique-query traffic stops, memory falls and the pod recovers on its own.

This is the classic "unbounded cache" leak. The fix is to **bound the cache**.

---

## Diagnosis Steps

### Step 1 — Confirm OOMKilled and restart loop

```bash
kubectl get pods -n commerce -o wide
kubectl get pod -n commerce -l app=commerce \
  -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.reason}{" exit="}{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
```

### Step 2 — Correlate with search traffic

```kql
AppRequests
| where AppRoleName == "commerce" and Url has "/catalog/search"
| where TimeGenerated > ago(1h)
| summarize requests=count(), distinctQueries=dcount(Url) by bin(TimeGenerated, 5m)
| order by TimeGenerated asc
```

A spike in `requests`/`distinctQueries` lining up with the memory ramp confirms the cause.

### Step 3 — Check the current cache bound

```bash
# Check environment variable on the deployment
kubectl get deploy commerce -n commerce \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="SEARCH_CACHE_MAX_SIZE")].value}{"\n"}'

# Check ConfigMap value
kubectl get configmap commerce-config -n commerce -o jsonpath='{.data.SEARCH_CACHE_MAX_SIZE}{"\n"}'
```

A value of `0` (or empty) means the cache is unbounded → leak confirmed.

---

## Remediation

### Preferred — Bound the cache (reproducible script)

```bash
# Apply the fix with default cap of 1000 entries
./scripts/fix-leak.sh

# Or specify a custom cap
./scripts/fix-leak.sh 2000
```

What the script does:

```bash
# Set the cache bound environment variable
kubectl set env deploy/commerce -n commerce SEARCH_CACHE_MAX_SIZE=1000

# Restart the deployment to clear leaked heap
kubectl rollout restart deploy/commerce -n commerce

# Wait for rollout to complete
kubectl rollout status deploy/commerce -n commerce --timeout=5m
```

With a positive `SEARCH_CACHE_MAX_SIZE` the application switches to a **bounded LRU cache**, so the map can no longer grow without limit. The rollout also clears heap retained by the leaking pods.

### Mitigations / Alternatives

| Action | Effect | When to use |
|--------|--------|-------------|
| Stop abusive traffic at source | Memory recovers on its own once unique-query traffic stops | Traffic is illegitimate (scanner, misbehaving client) |
| Raise memory limit to 1Gi | Buys time, does not fix root cause | Need breathing room while investigating |
| Persist cache bound in ConfigMap | Survives redeploys without manual `kubectl set env` | Permanent fix |

**Raise memory limit (temporary):**

```bash
kubectl set resources deploy/commerce -n commerce --limits=memory=1Gi
```

**Permanent fix (code):** the cache bound is already wired to `commerce.search-cache-max-size`. Persist a sane default in the ConfigMap (`k8s/base/configmap.yaml`) / Bicep so it survives redeploys, rather than relying on `kubectl set env`.

---

## Verification

```bash
# Confirm rollout completed
kubectl rollout status deploy/commerce -n commerce

# Confirm pods are healthy and restart count stops climbing
kubectl get pods -n commerce -o wide

# Confirm memory stabilizes well below 768Mi
kubectl top pod -n commerce
```

| Check | Expected Result |
|-------|----------------|
| Pod status | `Ready 1/1`, restart count stops increasing |
| Memory usage | Stabilizes well below 768 MiB |
| OOMKilled KQL | No new entries in the last 10 minutes |
| Alert status | `commerce-oomkilled` returns to **Resolved** (auto-mitigates within ~10–15 min once kills stop) |

---

## Rollback

Bounding the cache is safe and should not be rolled back. If you must revert to the original (leaking) configuration for a demo:

```bash
kubectl set env deploy/commerce -n commerce SEARCH_CACHE_MAX_SIZE=0
kubectl rollout restart deploy/commerce -n commerce
```

---

## Escalation

| Condition | Action |
|-----------|--------|
| OOMKills continue **after** bounding the cache and stabilizing traffic | Leak is elsewhere (not the search cache) |
| Next step | Capture a heap dump from the running container and inspect the dominator tree |
| Do not | Raise limits further without identifying the leak source |

---

## Related Resources

- [AKS Troubleshooting — OOMKilled (Microsoft Learn)](https://learn.microsoft.com/troubleshoot/azure/azure-kubernetes/welcome-azure-kubernetes)
- [Kubernetes: Managing Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Azure Monitor Container Insights](https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-overview)
- [Knowledge Base Index](../README.md)
