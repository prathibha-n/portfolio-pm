# Product Requirements Document
## Dark Store Slot-Utilisation Dashboard with Demand Forecast
**PIN 560068 — Bellandur, Bengaluru**

| Field | Detail |
|---|---|
| Author | Product Team |
| Date | April 2026 |
| Stakeholders | Ops Manager, WMS Lead, Category Manager, Finance |

---

## 1. Problem Statement

The Bellandur dark store operates 8 picker slots across three shifts. Scheduling is fixed and manual — the same number of pickers are rostered at 11 AM as at 7 PM, despite demand being roughly 2× higher in the evening. There is no system-level visibility into when slots are underutilised, which SKU categories drive spikes, or what demand will look like tomorrow. Restocking decisions are made on gut instinct or when a shelf visually "looks empty."

This creates two distinct, quantified consequences:

**Consequence 1 — Wasted labour cost during off-peak hours**

Analysis of 6 months of order data (Oct 2024 – Mar 2025) reveals the scale of idle capacity:

| Metric | Value |
|---|---|
| Underutilised hour-day combinations (util < 40%) | 145 out of 168 |
| Wasted picker-hours per week | ~952 hrs |
| Estimated weekly labour cost wasted | ₹1,14,230 |
| Estimated monthly labour cost wasted | ₹4,94,616 |

The waste is not evenly distributed. The overnight window (00:00–06:00) is the most consistently idle across all seven days. But significant waste also bleeds into mid-morning (10:00–12:00) on weekdays and early afternoon on all days — windows when pickers are rostered at full capacity despite demand dropping to 40–50% of peak.

**Consequence 2 — Queue delays and SLA breaches during peak hours**

The same fixed-roster problem that creates idle time in the morning creates overload in the evening. With all 8 slots running at the same pace regardless of demand, the evening surge (17:00–21:00) pushes utilisation above 85% — the threshold at which queue delays begin. This results in order delays of 4–6 minutes during the evening surge and an SLA breach rate (>15-minute delivery) of 11% of orders.

**The root cause of both problems is identical:** scheduling is not connected to demand. Fixing one fixes the other.

---

## 2. Hypothesis

> If we surface real-time slot occupancy data and layer a 7-day demand forecast onto the ops dashboard, store managers will be able to schedule picker slots dynamically — reassigning idle off-peak capacity to reinforce evening surge windows — reducing wasted labour cost by ≥₹50,000/month and cutting SLA breaches by ≥15% within 60 days of launch.

---

## 3. Proposed Solution

A single-screen ops dashboard (web + mobile) with four panels:

**Panel 1 — Live Slot Occupancy Heatmap**
Hour × day-of-week grid colour-coded by utilisation band: 🔴 Underutilised (<40%) / 🟢 Optimal (40–85%) / 🟡 Overloaded (>85%). Updates hourly from `fact_slot_activity`.

**Panel 2 — Wasted Capacity Summary**
Displays the current week's wasted picker-hours and rupee cost in real time, broken down by day of week. Includes a ranked list of the top 5 slot-hour combinations generating the most idle cost right now — the ops manager's daily action list.

**Panel 3 — 7-Day Demand Forecast**
Daily order volume forecast with 90% confidence intervals, powered by Prophet (MAPE 5.6% on holdout). Shows which upcoming days will spike so the manager can pre-position staff 24–48 hours in advance rather than reacting on the day.

**Panel 4 — SKU Fill-Rate and Stockout Tracker**
Per-category stockout rate over rolling 7/30 days. Flags categories approaching reorder threshold before a stockout occurs.

---

## 4. Waste Analysis Findings (Notebook Sections 4B–4F)

This section documents the specific findings from the picker capacity analysis. These findings directly shape the dashboard design, the success metrics in Section 5, and the sequencing of the rollout in Section 7.

### 4B — Quantified Waste

Using 8 picker slots at ₹120/hr and a 40% utilisation threshold, **145 out of 168 possible hour-day combinations are underutilised**. Total idle labour cost is approximately **₹4.9 lakh per month** — nearly half a month's equivalent of picker wages being paid for work that isn't happening.

The threshold logic: a slot is "wasted" when average utilisation falls below 40%, meaning the picker is idle for more than 36 minutes of every hour. Below this point, the cost of keeping the slot active outweighs any buffer value it provides.

### 4C — Waste by Hour of Day

When wasted picker-hours are aggregated across all seven days and ranked, the overnight and early morning hours (00:00–06:00) account for the largest absolute waste volume — demand is near-zero but slots remain nominally active.

However, the hours with the **highest financial impact** are in the 09:00–12:00 window. These hours have moderate but not zero demand, meaning they are chronically overstaffed relative to what's coming in. Reassigning one slot from this window to the 18:00–20:00 surge delivers a double benefit: a cost saving and a throughput gain.

The top 12 wasteful hours each cost between ₹3,000–₹8,000 per week individually — small enough that no single one feels urgent, but together they compound to over ₹1 lakh/week. The dashboard makes this cumulative picture visible, which manual inspection cannot.

### 4D — Waste Heatmap (Hour × Day)

The waste heatmap reveals three structural patterns that inform specific rostering decisions:

**Pattern 1 — Overnight waste is universal.**
Every day of the week has deep red cells from 01:00–05:00. This is the highest-confidence, lowest-risk action available: reducing the overnight roster from 8 to 2–3 slots would save approximately ₹20,000–₹25,000/week with near-zero SLA risk because demand in this window is near-zero.

**Pattern 2 — Weekday mid-morning slack.**
Tuesday through Thursday between 10:00–12:00 show consistent waste, reflecting the post-breakfast lull before the lunch nudge. These slots are candidates for a 2-slot reduction during this window, with those pickers shifted to the 18:00 surge.

**Pattern 3 — Weekend afternoons are underutilised.**
Counter-intuitively, Saturday and Sunday afternoons (13:00–16:00) are wasteful despite weekends being higher-demand overall. The evening surge on weekends is intense but narrow (18:00–21:00); the afternoon hours before it are quiet. Current rostering doesn't account for this shape — it staffs the full weekend uniformly rather than front-loading the evening.

### 4E — Day-of-Week Breakdown

| Day | Wasted Hrs/Week | Weekly Cost (₹) | Monthly Cost (₹) | Peak Waste Hour |
|---|---|---|---|---|
| Wednesday | Highest | ~₹17,000 | ~₹74,000 | 04:00 |
| Sunday | High | ~₹16,500 | ~₹71,000 | 03:00 |
| Thursday | High | ~₹16,000 | ~₹69,000 | 03:00 |
| Monday | Moderate | ~₹15,000 | ~₹65,000 | 04:00 |
| Tuesday | Moderate | ~₹15,000 | ~₹65,000 | 03:00 |
| Friday | Lower | ~₹13,000 | ~₹56,000 | 03:00 |
| Saturday | Lowest | ~₹11,000 | ~₹48,000 | 04:00 |

Wednesday is consistently the worst-performing day for idle capacity. This is notable because it has no natural demand driver — no pay-cycle effect, no weekend uplift, no festival proximity. It is a purely structural overstaffing problem, and the most straightforward to fix.

Saturday has the lowest waste because the weekend demand uplift absorbs more available capacity, even though the peak is narrow. This confirms that the weekend problem is not understaffing overall — it is staffing the wrong hours.

### 4F — Reallocation Recommendations

The analysis generates slot-level reallocation recommendations by identifying the top 10 most wasteful hour-day combinations and computing how many slots should be reduced. The methodology: remove 60% of idle slots (floored to nearest integer, minimum 1 removal). This is intentionally conservative — it retains a buffer for demand variability and avoids over-correcting in one move.

**Top 5 reallocation actions by weekly saving:**

| # | Action | Current Utilisation | Weekly Saving |
|---|---|---|---|
| 1 | Reduce slots 8→4 on Wed 04:00 | 0.6% | ₹480 |
| 2 | Reduce slots 8→4 on Sun 03:00 | 0.7% | ₹480 |
| 3 | Reduce slots 8→4 on Sun 04:00 | 0.7% | ₹480 |
| 4 | Reduce slots 8→4 on Mon 04:00 | 0.6% | ₹480 |
| 5 | Reduce slots 8→4 on Thu 03:00 | 0.8% | ₹480 |

**Combined saving from top 10 actions: ₹4,800/week → ₹20,784/month**

**Why the per-action saving looks small:** Each individual overnight slot-hour saves ₹480/week because it's one slot for one hour. The financial scale appears when you multiply across multiple slots, multiple hours, and 7 days. The total ₹4.9 lakh/month waste figure is the accumulation of hundreds of these small gaps. The dashboard's core value is precisely this: it makes the cumulative picture visible so the manager can act on it systematically rather than slot by slot.

**Important constraint for the dashboard:** The waste panel and the 7-day forecast must be displayed side by side on the same screen. A reallocation recommendation should never be acted on without checking what demand is expected that day. If the forecast shows a spike on the same day as a recommended slot reduction, the dashboard must surface a warning flag to prevent the manager from inadvertently understaffing a high-demand shift.

---

## 5. Success Metrics

| Metric | Baseline | Target (Day 60) | How Measured |
|---|---|---|---|
| Slot utilisation % | ~62% | ≥80% | `fact_slot_activity` daily rollup |
| Idle minutes / slot / day | ~190 min | ≤130 min | Same table |
| Wasted labour cost / month | ₹4,94,616 | ≤₹2,50,000 | 4B waste query re-run on live data weekly |
| SLA breach rate (>15 min) | 11% of orders | ≤7% | `fact_orders` delivery_ts delta |
| Stockout rate | 8.2% of snapshots | ≤4% | `fact_inventory_snapshot` |
| Forecast MAPE | N/A | ≤8% | Model evaluation on weekly holdout |

The wasted labour cost metric is new in v1.1. It is the most direct financial signal and the one Finance will track. It is computed using the same logic as notebook section 4B: sum of `(idle_picker_slots × ₹120)` for all hour-day combinations below the 40% utilisation threshold, run as a weekly batch query. Both the ₹120/hr rate and the 40% threshold are configurable parameters in the stored procedure so Finance can stress-test the assumptions.

---

## 6. Non-Goals (v1)

- Automated picker rostering triggered by the dashboard (v2 scope)
- Multi-store aggregation across PIN codes
- Customer-facing ETA changes
- Real-time slot reassignment alerts pushed to picker devices

---

## 7. Rollout Plan

**Week 1–2 — Data plumbing**
Verify WMS → `fact_slot_activity` pipeline. Backfill 90 days of history. Validate `slot_capacity` values with the ops team — the waste calculation is sensitive to this number being accurate. A single incorrect slot_capacity value can materially inflate or deflate the waste figure.

**Week 3–4 — Model + Dashboard build**
Deploy Prophet model as a daily batch job (cron, 05:00 IST). Build Metabase / Grafana dashboard wired to SQL queries and the 4B waste computation as a nightly stored procedure. Internal UAT with the store manager — specifically validate that the 4F reallocation recommendations match their intuition about quiet periods. If they say "that's obviously right," the methodology is sound.

**Week 5 — Soft launch + first 4F action**
Bellandur store only. Implement the highest-confidence 4F recommendation immediately: reduce the overnight roster (01:00–05:00) from 8 slots to 3. This is the lowest-risk action — near-zero demand, clear data support, and it generates immediate monthly savings before the full dashboard is live. Use this as the before/after comparison point for the wasted labour cost metric.

**Week 6–8 — A/B test**
Run ML-driven restocking trigger vs manual threshold (see `04_AB_test_design.md`). Monitor all six success metrics. The overnight roster change from Week 5 provides a clean natural experiment for the labour cost metric independent of the A/B test.

**Week 9+ — Rollout decision**
If wasted labour cost has dropped by ≥40% and SLA breach rate has not worsened: expand to 3 more PIN codes — 560034 (Koramangala), 560095 (Whitefield), 560037 (Indiranagar). Apply the overnight roster reduction (4F action #1–5) at each new store on day one of expansion, since the overnight pattern is consistent across Bengaluru dark stores.

---

## 8. Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| WMS data quality gaps skew the waste calculation | Medium | Daily validation alert if `fact_slot_activity` rows fall below expected count; spot-check `slot_capacity` values monthly |
| Manager reduces slots during an upcoming demand spike by following 4F without checking the forecast | Medium | Dashboard must show waste heatmap and 7-day forecast side by side; add a warning flag when a recommended slot reduction falls on a high-forecast day |
| Overnight roster reduction causes missed orders from late-night demand events | Low | Enforce a minimum of 2 active slots at all times; review all orders placed 01:00–05:00 in the prior 30 days before reducing |
| Forecast degrades during festival periods, leading to understaffing on Diwali/Ugadi | High | Re-train Prophet weekly; send manager a manual "high demand alert" 3 days before each major holiday; treat festival weeks as manual-override periods |
| Finance rejects the ₹4.9 lakh/month waste figure as inflated | Medium | Walk Finance through the 4B methodology in the notebook; both the ₹120/hr rate and the 40% threshold are configurable; provide a conservative scenario at ₹100/hr and 30% threshold for comparison |
| Privacy / picker surveillance concern from efficiency leaderboard | Low | Aggregate all dashboard views to slot level; never display individual picker names or IDs in any panel |
