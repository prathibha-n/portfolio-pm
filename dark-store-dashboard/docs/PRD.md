# Product Requirements Document
## Dark Store Slot-Utilisation Dashboard — SwiftMart Koramangala (PIN 560068)

**Author:** Product Manager, Supply Operations
**Date:** April 2026 | **Status:** Draft — Ready for Engineering Review
**Stakeholders:** WMS Engineering, Dark Store Ops, Data Science, Finance

---

## Problem

SwiftMart's Koramangala dark store (PIN 560068) operates 12 picker slots across 20 operating hours. Observational data shows **picker idle time averaging 38 minutes/hour during off-peak windows** (02:00–07:00, 10:00–12:00) while **stockouts in Dairy and F&V spike 2× during peak hours** (12:00–14:00, 18:00–21:00) — precisely when pickers are capacity-constrained and cannot restock mid-shift. The current restocking system uses static manual thresholds (reorder point = 20 units, fixed), which neither adapts to intraday demand patterns nor signals proactively.

**Impact today:** ~₹1.4L/month in lost GMV from stockouts (est.); ~18% of scheduled picker-slot-hours are idle, representing ₹80K/month in preventable labour cost.

---

## Hypothesis

> If we replace static reorder thresholds with a demand-forecast-driven restocking trigger (ML model: 7-day ARIMA/Prophet per SKU-hour), pickers will be redirected to proactive restocking during predicted low-order windows — reducing stockout rate by ≥20% and improving slot fill-rate from ~62% to ≥75%, without increasing labour spend.

---

## Goals & Success Metrics

| Metric | Baseline | Target (90 days) | Source |
|--------|----------|-------------------|--------|
| Picker slot fill-rate | 62% | ≥ 75% | `slot_utilisation_hourly.fill_rate` |
| Stockout rate (SKU-hours OOS / total SKU-hours) | 8.4% | ≤ 5% | `stockout_events` |
| Avg stockout duration | 47 min | ≤ 25 min | `stockout_events.stockout_duration_min` |
| Lost orders from OOS | ~310/month | ≤ 180/month | `stockout_events.lost_order_count` |
| Labour cost per order | ₹14.2 | ≤ ₹13.0 | Picker sessions ÷ orders |
| P95 picking SLA (< 8 min) | 71% | ≥ 82% | `orders` delta timestamps |

**Counter-metric (must not worsen):** Delivery promise fulfilment rate ≥ 96%.

---

## Solution Overview

### Phase 1 — Dashboard & Observability (Weeks 1–3)
- Materialise `slot_utilisation_hourly` via dbt scheduled job (every 30 min)
- Superset / Metabase dashboard: fill-rate heatmap, idle-time alerts, category fill-rate drill-down
- PagerDuty alert if any hour's fill-rate falls below 40% for 2 consecutive hours

### Phase 2 — Demand Forecast Model (Weeks 4–7)
- ARIMA + Prophet ensemble per (store_id, sku_category, hour_of_day)
- Retrained weekly on rolling 90-day window; MAE ≤ 15% of mean demand
- Model output: `predicted_orders_next_7d` written to `demand_forecasts` table hourly

### Phase 3 — ML Restocking Trigger (Weeks 8–10)
- New WMS signal: when `predicted_orders_next_2h < P25(historical)` AND `stock_on_hand < 2 × predicted_demand`, emit `RESTOCK_TASK` to picker queue
- Replaces: manual check-list restocking currently done at shift start only
- A/B tested (see A/B Design Doc) before full rollout

---

## Rollout Plan

| Week | Milestone | Owner |
|------|-----------|-------|
| 1–2  | Schema migration, dbt pipeline live | Data Eng |
| 3    | Dashboard v1 in Metabase, ops team trained | PM + Analytics |
| 4–5  | Forecast model trained, backtested, MAE < 15% | DS |
| 6    | Shadow mode: ML trigger logs without acting | DS + WMS Eng |
| 7    | A/B experiment begins (50% stores treatment) | PM + Eng |
| 10   | Interim readout; ship if p < 0.05 on fill-rate | PM + DS |
| 12   | Full rollout or iterate | PM |

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Forecast degrades during festivals (Diwali, Ugadi) | High | Add `is_festival_day` regressor; retrain 2 weeks pre-festival |
| Pickers ignore ML task queue | Medium | In-app prompt on WMS handheld; ops lead SOP |
| Overrestocking ties up cold-chain capacity | Low | Cap restock tasks to available cold-storage slots |

---

## Out of Scope (v1)
- Multi-store rollout beyond Koramangala
- Real-time demand sensing via social signals
- Automated vendor purchase orders (Phase 2 roadmap)
