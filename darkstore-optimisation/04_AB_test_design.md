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
TBD by Data team

## 7. Data Requirements
TBD by Data team


---

## 8. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Forecast cold-start for new SKUs | Exclude SKUs with <14 days of history from Treatment arm |
| Concept drift during festival week | Pre-register test; exclude Ugadi weekend (March 30) from analysis or add as covariate |
| Peeking / early stopping | Lock analysis until Day 28; changes only if a guardrail is breached |

---

## 9. Decision Criteria

| Outcome | Decision |
|---|---|
| Stockout rate decreases ≥2.5 pp, p < 0.05, no guardrail breached | **Ship Treatment** — ML trigger replaces manual threshold for all SKUs |
| Stockout rate decreases <2.5 pp but trends positive, no harm | **Iterate** — retrain model with more features, re-test in 30 days |
| Any guardrail metric worsens | **Do not ship** — investigate model quality, check for data pipeline issues |

---
