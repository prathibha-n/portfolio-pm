# EV Transition — Driver Cohort Analysis & Incentive Design
> Ridehailing EV transition strategy for Indian mobility platforms · Bengaluru-first

A product strategy toolkit for converting active petrol/diesel/CNG drivers to EVs on ridehailing platforms (Uber India, Rapido, Ola, Porter). Combines a SQL-based driver targeting model with a full product spec for the incentive system and in-app charging finder.

---

## Overview

The path to a zero-emissions fleet is blocked not by driver resistance to EVs, but by three discrete, addressable barriers:

- **Capital barrier** — upfront EV cost is prohibitive despite strong daily earnings
- **Infrastructure anxiety** — drivers fear being stranded mid-shift without a nearby charger
- **Information gap** — no reliable, real-time view of charging availability in the driver workflow

This repo provides the analytical and product foundation to address all three — starting with identifying *which* drivers to target and *how* to convert them.

---

## Files

| File | Description |
|---|---|
| `ev_driver_cohort.sql` | Segments active non-EV drivers into conversion tiers using behavioural proxies |
| `ev_cohort_sample_output.csv` | Sample output from the cohort query (7 rows × 9 columns) |
| `cancellation_risk_model.md` | Design rationale for the risk signal and threshold sensitivity analysis |
| `ev_transition_prd.md` | Full PRD — incentive tiers, charging finder spec, UX escalation ladder, launch sequencing |

---

## How it works

### Step 1 — Identify the right drivers

`ev_driver_cohort.sql` runs against a 90-day rolling window of trip and driver data. Rather than targeting by vehicle age alone, it scores drivers on behavioural proxies that signal a natural EV use case:

| Signal | Why it matters |
|---|---|
| `avg_trip_dist_km ≤ 12` | Short trips are well within EV range |
| `city_centre_share ≥ 0.6` | City-centre routes are predictable and near charging infrastructure |
| `avg_daily_trips ≥ 8` | High volume means faster subsidy payback |
| `tenure_months ≥ 6` | Platform commitment reduces churn risk on incentive spend |

Drivers are bucketed into three tiers, and three sub-segment flags are computed per driver:

| Flag | Meaning | Unlocks |
|---|---|---|
| `natural_ev_profile` | Short trips + high city-centre density | Charging finder feature — no cash needed |
| `financially_motivated` | High daily volume + peak-hour concentration | Earnings guarantee |
| `likely_cash_constrained` | Long tenure + aging vehicle, no upgrade | 0% interest EV loan tie-up |

The cohort output is the direct input to the incentive budget model — each flag maps to a line item in spend.

### Step 2 — Convert them with the right offer

`ev_transition_prd.md` is the product spec for everything a driver sees after they're identified. It covers:

- **Incentive tier structure** — subsidy amounts, earnings guarantees, loan tie-ups, and priority queue boosts per tier
- **Stacking rules** — a `financially_motivated` Tier 1 driver chooses between the ₹15,000 cash subsidy *or* an enhanced earnings guarantee, not both. Cash attracts opportunistic converts; the earnings guarantee self-selects for drivers who intend to run on EV
- **In-app charging finder** — surfaces contextually at trip acceptance, between-trip idle state, and as a proactive planning tab. Live slot availability via OCPI API
- **Battery-anxiety escalation ladder** — three progressive interventions (soft nudge → route insert → demand pause) triggered when battery ≤ 25%. Only the final stage (≤10%) is non-optional
- **Launch sequencing** — four phases with success gates, starting with a finder-only soft launch to the highest-anxiety cohort before any cash is spent

---

## Launch logic

```
ev_driver_cohort.sql
        │
        ├── natural_ev_profile      ──► Phase 0: charging finder soft launch (~951 drivers, BLR)
        ├── tier_1 cohort           ──► Phase 1: incentive A/B pilot (~1,840 drivers, BLR)
        ├── tier_1 + tier_2         ──► Phase 2: city expansion (BLR + DEL + MUM)
        └── all tiers, all cities   ──► Phase 3: full rollout
```

**Phase 0 is the critical gate.** The charging finder is launched to the high-anxiety cohort before any subsidy spend. If finder engagement alone reduces battery cancel rate by ≥20%, the binding constraint for that sub-segment is information — not capital — and the budget can be reallocated accordingly.

---

## Running the SQL

```sql
-- Tested on BigQuery and Postgres (see dialect notes below)
\i ev_driver_cohort.sql
```

Adjust tier thresholds at the top of the file to match your driver distribution. See `cancellation_risk_model.md` for sensitivity analysis — loosening `avg_daily_trips` from 8 to 6, for example, expands the Tier 1 pool by ~55% but increases adverse selection risk.

### Dialect notes

`COUNTIF()` and `DATEDIFF()` are BigQuery idioms. Postgres equivalents:

```sql
-- BigQuery                              -- Postgres
COUNTIF(condition)                       COUNT(CASE WHEN condition THEN 1 END)
DATEDIFF(date1, date2)                   DATE_PART('day', date1 - date2)
```

---

## Related

| | |
|---|---|
| `ev_hub_placement.ipynb` | Charging hub placement model — demand heatmap × dwell-time scoring with time-of-day segmentation |
| Deliverable 4 | Growth experiment plan — EV adoption funnel, A/B test design, sample size calculation |
