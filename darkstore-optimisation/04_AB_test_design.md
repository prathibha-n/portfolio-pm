# A/B Test Design Document
## ML-Driven Restocking Trigger vs Manual Threshold
**Dark Store PIN 560068 — Bellandur, Bengaluru**

| Field | Detail |
|---|---|
| Test Owner | Data Team |
| Status | Proposed |
| Planned Start | Week 6 post-dashboard launch |
| Duration | 28 days |

---

## 1. Background & Motivation

Currently, pickers are prompted to restock a SKU when a store manager manually notices low shelf stock or when a fixed quantity threshold is crossed (e.g., "restock when units < 10"). This threshold is the same regardless of time-of-day or upcoming demand.

The hypothesis is that a Prophet-based forecast can predict demand surges 4–6 hours in advance and trigger restocking *before* a stockout occurs, rather than *after*. This should reduce stockout events and reduce picker congestion (pickers restocking while simultaneously fulfilling orders).

---

## 2. Experiment Design

### Treatment vs Control

| | Control (Group A) | Treatment (Group B) |
|---|---|---|
| **Trigger logic** | Restock when `stock_on_hand < reorder_point` (static) | Restock when `stock_on_hand < predicted_demand_next_4h × 1.2` |
| **Reorder point** | Fixed per SKU (set manually by category team) | Dynamic: updated every hour using hourly Prophet forecast |
| **Who decides** | Picker responds to WMS alert | WMS alert auto-generated from ML model output |
| **Picker action** | Identical — walk to back-store, restock shelf | Identical |

The picker experience is the **same** in both arms. Only the *trigger timing* differs. This ensures the test measures forecasting quality, not behaviour change.

---

## 3. Randomisation Unit

**SKU × time-slot**, not order or picker.

- Each SKU is randomly assigned to Control or Treatment at the start of the experiment and stays in its arm for the full 28 days.
- 50/50 split across SKU categories to avoid imbalance (e.g., don't put all Dairy in Treatment).
- Rationale: SKU-level randomisation avoids spillover — a picker restocking a Treatment SKU won't affect a nearby Control SKU's fill level.

### Stratification
Stratify by SKU category (Grocery, Dairy, Snacks, Beverages, Personal Care, Frozen) to ensure equal representation in each arm.

---

## 4. Sample Size & Power Calculation

**Primary metric**: Stockout rate (proportion of hourly snapshots where `stockout_flag = TRUE`)

- Baseline stockout rate: **8.2%** (30-day historical average)
- Minimum detectable effect (MDE): **−2.5 pp** (i.e., Treatment reduces to ≤5.7%)
- α = 0.05 (two-tailed), Power = 0.80

Using standard two-proportion z-test:

```
n ≈ 2 × [(z_α/2 + z_β)² × (p1(1−p1) + p2(1−p2))] / (p1 − p2)²
n ≈ 2 × [(1.96 + 0.84)² × (0.082×0.918 + 0.057×0.943)] / (0.025)²
n ≈ 2 × [7.84 × (0.0753 + 0.0537)] / 0.000625
n ≈ 2 × [7.84 × 0.1290] / 0.000625
n ≈ 3,235 SKU-hour observations per arm
```

With ~120 active SKUs × 17 operating hours × 28 days = **57,120 observations per arm** — well above the required minimum. We are **not sample-size constrained**.

---

## 5. Primary & Secondary Metrics

### Primary (guardrail pass required)
| Metric | Direction | Notes |
|---|---|---|
| Stockout rate | Decrease | Core hypothesis metric |

### Secondary
| Metric | Direction | Notes |
|---|---|---|
| Idle picker minutes / hour | Decrease | Fewer reactive restock runs = less congestion |
| Restock events / day | Decrease | More efficient batching |
| SLA breach rate | Decrease | Indirect benefit of fewer stockouts |

### Guardrails (must not worsen)
| Metric | Threshold |
|---|---|
| Order pick time | Must not increase by >5% |
| Wasted restock trips (restocked but no demand) | Must not increase by >10% |

---

## 6. Statistical Analysis Plan

- **Test**: Two-proportion z-test for stockout rate; Welch's t-test for continuous metrics
- **Corrections**: Bonferroni correction for 3 secondary metrics (α_adjusted = 0.017 per test)
- **Segmentation**: Run analysis separately for each SKU category to catch heterogeneous effects
- **Novelty effect check**: Compare Week 1 vs Week 2–4 Treatment performance; flag if large divergence
- **Temporal bias check**: Ensure both arms have equal representation across peak hours (17:00–21:00) and weekends

---

## 7. Data Requirements

```sql
-- Experiment assignment table
CREATE TABLE experiment_assignments (
    sku_id       INT REFERENCES dim_sku(sku_id),
    arm          TEXT NOT NULL CHECK (arm IN ('control', 'treatment')),
    assigned_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Log every restock trigger and its source
CREATE TABLE restock_log (
    log_id        BIGSERIAL PRIMARY KEY,
    sku_id        INT REFERENCES dim_sku(sku_id),
    trigger_ts    TIMESTAMP NOT NULL,
    trigger_type  TEXT NOT NULL,      -- 'static_threshold' | 'ml_forecast'
    stock_at_trigger INT,
    forecast_demand  INT,
    stockout_occurred BOOLEAN
);
```

---

## 8. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| SUTVA violation (pickers serve both arms) | Acceptable — intervention is system-side, not picker behaviour |
| Forecast cold-start for new SKUs | Exclude SKUs with <14 days of history from Treatment arm |
| Concept drift during festival week | Pre-register test; exclude Ugadi weekend (March 30) from analysis or add as covariate |
| Peeking / early stopping | Lock analysis until Day 28; use sequential testing (mSPRT) only if a guardrail is breached |

---

## 9. Decision Criteria

| Outcome | Decision |
|---|---|
| Stockout rate decreases ≥2.5 pp, p < 0.05, no guardrail breached | **Ship Treatment** — ML trigger replaces manual threshold for all SKUs |
| Stockout rate decreases <2.5 pp but trends positive, no harm | **Iterate** — retrain model with more features, re-test in 30 days |
| Any guardrail metric worsens | **Do not ship** — investigate model quality, check for data pipeline issues |

---

## 10. Experiment Timeline

| Week | Activity |
|---|---|
| 0 | SKU randomisation + `experiment_assignments` table populated |
| 1 | Soft launch; daily sanity check on data volumes in both arms |
| 2–3 | Monitor guardrails only; no peeking at primary metric |
| 4 | Full analysis; prepare results deck |
| 4+ | Rollout or iterate decision |
