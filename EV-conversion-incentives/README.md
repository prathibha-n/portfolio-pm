# EV Transition — Driver Cohort Analysis & Incentive Design
> Ridehailing EV transition strategy for Indian mobility platforms · Bengaluru-first

A product strategy toolkit for converting active petrol/diesel/CNG drivers to EVs on ridehailing platforms (Uber India, Rapido, Ola, Porter). Combines a SQL-based driver targeting model with a full product spec for the incentive system.

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
| `ev_transition_prd.md` | Full PRD — incentive tiers, charging finder spec, UX escalation ladder, launch sequencing |

---

## How it works

### Step 1 — Identify the right drivers

`ev-driver-cohort.sql` runs against a 90-day rolling window of trip and driver data. Rather than targeting by vehicle age alone, it scores drivers on behavioural proxies that signal a natural EV use case:

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
