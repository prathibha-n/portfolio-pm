# A/B Test Design Document
## Experiment: ML-Driven Restocking Trigger vs Manual Threshold
**Experiment ID:** EXP-001 | **Status:** Design Phase
**Owner:** PM, Supply Operations | **DS Partner:** Forecasting Team
**Target Start:** Week 7 of roadmap (~June 2026)

---

## 1. Hypothesis

**H0 (null):** The ML-driven restocking trigger produces no significant difference in picker slot fill-rate or stockout rate compared to the manual threshold system.

**H1 (alternative):** Treatment stores (ML trigger) will achieve ≥5 percentage-point higher fill-rate AND ≥2 percentage-point lower stockout rate within 6 weeks of activation.

---

## 2. Unit of Randomisation

**Randomisation unit:** Dark store (not individual picker, not SKU)

**Rationale:** The treatment operates at store level (WMS task queue is store-scoped); picker-level or SKU-level randomisation would create SUTVA violations — a restock decision in one aisle affects order completion elsewhere in the same store.

**Population:** All SwiftMart dark stores in Bengaluru operating ≥ 3 months (removes novelty bias from new stores).

---

## 3. Variant Design

| Variant | n (stores) | Restocking Logic |
|---------|-----------|------------------|
| **Control** | 8 | Manual threshold: reorder when `stock_on_hand ≤ 20 units` (fixed), checked at shift start only |
| **Treatment** | 8 | ML trigger: reorder when `stock_on_hand ≤ ml_reorder_point` (dynamic, forecast-driven), checked every 30 min |

**Assignment method:** Stratified randomisation on store GMV quintile (to balance high/low-volume stores across arms) and day-of-week operational hours.

**Blinding:** Pickers in treatment stores receive restock tasks via existing WMS queue UI — no UI change that signals "experiment mode."

---

## 4. Primary Metrics

| Metric | Formula | Direction | MDE |
|--------|---------|-----------|-----|
| Picker slot fill-rate | `1 - (idle_slot_min / total_slot_min)` per store-hour | ↑ | +5 pp |
| SKU-level stockout rate | `OOS sku-hours / total sku-hours` | ↓ | −2 pp |

---

## 5. Secondary Metrics

| Metric | Direction | Notes |
|--------|-----------|-------|
| Avg stockout duration (min) | ↓ | Measures speed of restock response |
| Lost orders from OOS | ↓ | Revenue proxy; compare against GMV growth |
| P95 pick-to-pack time | ↓ | Ensure ML tasks don't interrupt active picking |
| Labour cost per order (₹) | ↓ or neutral | Must not increase |

**Guardrail metrics (experiment pauses if breached):**
- Delivery promise SLA < 94% in either arm
- App crash rate increase > 0.5% (WMS app)
- Any food safety complaint attributable to cold-chain restock logic

---

## 6. Sample Size & Power Calculation

**Assumptions:**
- Baseline fill-rate: 62% | SD ≈ 8 pp (from 30-day data)
- MDE: 5 pp absolute lift
- α = 0.05 (two-tailed) | Power (1−β) = 0.80
- Observations: store-hours (each store contributes ~20 obs/day × 6 weeks = 840 obs/store)

**Required stores per arm:**

```
n = 2 × [(z_α/2 + z_β)² × σ²] / δ²
  = 2 × [(1.96 + 0.84)² × 64] / 25
  ≈ 2 × [7.84 × 64] / 25
  ≈ 2 × 20.1
  ≈ 41 store-weeks per arm
```

With 8 stores per arm × 6 weeks = **48 store-weeks per arm** — adequately powered.

**Note:** If fewer than 8 stores are available per arm, extend duration to 8 weeks.

---

## 7. Duration

| Phase | Duration | Purpose |
|-------|----------|---------|
| Pre-experiment (AA test) | 1 week | Verify no pre-existing fill-rate difference between groups |
| Ramp | 3 days | 10% → 50% → 100% treatment stores activated (catch bugs) |
| Main experiment | 6 weeks | Captures 2 full weekday + weekend cycles × 3 iterations |
| Cooldown analysis | 1 week | Check for delayed effects (cold-chain replenishment lag) |

---

## 8. SUTVA & Interference Checks

1. **Demand spillover:** Customers in Bengaluru use multiple quick-commerce apps; treatment stores improving availability may attract demand away from control stores. Mitigate by choosing geographically distinct store catchments (>3 km apart).

2. **Inventory pooling:** If stores share a central DC and ML restock requests increase DC dispatch frequency, control stores may benefit indirectly. Track DC dispatch-per-store-per-day as a balance check.

3. **Picker movement:** Some pickers rotate across stores. Track `picker_id` cross-assignment in `picker_sessions`; exclude migrating pickers from per-picker metrics (store-level metrics unaffected).

---

## 9. Analysis Plan

**Primary analysis:** Mixed-effects regression at store-hour level
```
fill_rate ~ variant + hour_of_day + day_of_week + store_gmv_quintile
            + (1 | store_id) + (1 | experiment_week)
```

- `variant` coefficient = treatment effect estimate
- Report 95% CI; claim success only if CI lower bound > 0 for fill-rate lift

**Secondary analysis (stockout rate):** Negative binomial regression on count of OOS sku-hours; report IRR and 95% CI.

**Interim look:** At Week 3 using O'Brien-Fleming boundary (α_interim = 0.005) — stop early only for harm (guardrail breach), not for early success.

**Multiple comparison correction:** Bonferroni across 2 primary metrics → adjusted α = 0.025 per metric.

---

## 10. Rollout Decision Tree

```
Week 6 Readout
    │
    ├─ Fill-rate lift ≥ 5 pp AND stockout Δ ≥ 2 pp, p < 0.025
    │      → Full rollout to all Bengaluru stores (Week 12)
    │
    ├─ Fill-rate lift 3–5 pp, directionally positive
    │      → Extended test (4 more weeks) + model tuning
    │
    ├─ No significant difference
    │      → Investigate feature importance; consider richer regressors (weather, events)
    │
    └─ Guardrail breach (SLA drop or labour cost increase)
           → Immediate pause; root-cause analysis before any restart
```

---

## 11. Logging & Instrumentation Required

| Event | Table | Notes |
|-------|-------|-------|
| Restock task emitted | `restock_task_log` | Log trigger source (ml / manual) |
| Picker accepts task | `picker_order_assignments` | Already instrumented |
| Stock replenished | `inventory_snapshots` | Delta check vs prior snapshot |
| Stockout detected / resolved | `stockout_events` | Flag `restock_trigger` = 'ml_model' |
| Experiment assignment | `ab_store_assignments` | Log once at randomisation |

---

## 12. Risks to Experiment Validity

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Novelty effect in treatment stores | Medium | Discard first 3 days (ramp period) from analysis |
| ML model degrades in Week 3–4 | High | Monitor MAE daily; auto-fallback to manual threshold if MAE > 25% |
| Festive spike during experiment window | Medium | Add `is_festival_day` covariate; avoid experiment over major festivals |
| Ops team bypasses ML queue | Medium | Track override rate; alert if > 15% of ML tasks are manually dismissed |
