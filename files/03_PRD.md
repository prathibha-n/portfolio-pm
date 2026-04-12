# Product Requirements Document
## Dark Store Slot-Utilisation Dashboard with Demand Forecast
**PIN 560068 — Bellandur, Bengaluru**

| Field | Detail |
|---|---|
| Author | Data / Product Team |
| Status | Draft v1.0 |
| Date | April 2025 |
| Stakeholders | Ops Manager, WMS Lead, Category Manager |

---

### Problem Statement

The Bellandur dark store operates 8 picker slots across three shifts. Current scheduling is fixed and manual — the same number of pickers are rostered at 11 AM as at 7 PM, despite demand being 2× higher in the evening. This results in **idle picker time of ~35–40 minutes per hour during off-peak windows** and **order queue delays of 4–6 minutes during evening surge**, directly hurting our sub-15-minute delivery SLA.

There is no system-level visibility into when slots are underutilised, which SKU categories drive spikes, or what demand will look like tomorrow. Restocking decisions are made on gut instinct or when a shelf visually "looks empty."

---

### Hypothesis

> If we surface real-time slot occupancy and layer a 7-day demand forecast onto the ops dashboard, store managers will be able to schedule picker slots dynamically — reducing idle time by ≥20% and cutting SLA breaches by ≥15% within 60 days of launch.

---

### Proposed Solution

A single-screen ops dashboard (web + mobile) that shows:

1. **Live slot occupancy heatmap** — hour × day-of-week grid, colour-coded by utilisation band (underutilised / optimal / overloaded)
2. **7-day demand forecast** — daily order volume with 90% confidence intervals, powered by Prophet
3. **SKU fill-rate panel** — per-category stockout rate over rolling 7/30 days
4. **Idle time leaderboard** — which picker slots are chronically under-assigned

---

### Success Metrics

| Metric | Baseline | Target (Day 60) | How Measured |
|---|---|---|---|
| Slot utilisation % | ~62% | ≥80% | `fact_slot_activity` daily rollup |
| Idle minutes / slot / day | ~190 min | ≤130 min | Same table |
| SLA breach rate (>15 min) | 11% of orders | ≤7% | `fact_orders` delivery_ts delta |
| Stockout rate | 8.2% of snapshots | ≤4% | `fact_inventory_snapshot` |
| Forecast MAPE | N/A | ≤8% | Model evaluation on weekly holdout |

---

### Non-Goals (v1)

- Automated picker rostering (v2 scope)
- Multi-store aggregation
- Customer-facing ETA changes

---

### Rollout Plan

**Week 1–2 — Data plumbing**
Verify WMS → `fact_slot_activity` pipeline; backfill 90 days of history; validate slot_capacity values with ops team.

**Week 3–4 — Model + Dashboard**
Deploy Prophet model as a daily batch job (cron, 05:00 IST). Build Metabase / Grafana dashboard wired to the SQL queries. Internal UAT with store manager.

**Week 5 — Soft launch**
Bellandur store only. Manager uses dashboard for scheduling decisions; no automation yet. Collect qualitative feedback.

**Week 6–8 — A/B test**
Run ML-driven restocking trigger vs manual threshold (see A/B design doc). Monitor all five success metrics.

**Week 9+ — Rollout decision**
If target metrics are met: expand to 3 more PIN codes (560034 Koramangala, 560095 Whitefield, 560037 Indiranagar).

---

### Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| WMS data quality gaps | Medium | Add data validation step + daily alert if slot_activity rows < expected |
| Manager adoption | Medium | Embed dashboard in existing ops WhatsApp bot as daily summary card |
| Forecast degrades during festival periods | High | Re-train Prophet weekly; add festival flag features |
| Privacy / picker surveillance concern | Low | Aggregate to slot level, never individual names in dashboard |
