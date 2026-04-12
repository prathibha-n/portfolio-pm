# PRD — EV Driver Cohort Identification & Incentive Targeting

**Product area:** Driver Platform — Electrification  
**Applicable platforms:** Uber India, Rapido, Ola, and any ridehailing operator with a driver fleet in Indian metros  
**Status:** Draft v1.0  
**Last updated:** April 2026

---

## 1. Problem statement

The platform's non-EV driver base is not uniformly resistant to switching. A large subset already has the right behavioural profile for an EV — short trips, city-centre routes, high daily utilisation — but has not converted. The barrier is not intent; it is capital access, earnings uncertainty, or a simple information gap.

The task this PRD addresses is: **how do we identify which drivers are worth targeting, in what priority order, and with which specific incentive lever?** Getting the cohort wrong wastes subsidy budget on drivers who will not convert or do not need help. Getting the signals right means each incentive rupee is matched to the actual barrier standing between a driver and an EV.

---

## 2. The right cohort to target

### 2.1 Baseline filter

Before scoring, every driver must pass a baseline filter. Drivers outside this filter are excluded from all targeting.

| Filter | Condition | Rationale |
|---|---|---|
| Active | `is_active = TRUE` | Inactive drivers will not respond to EV offers |
| Not already EV | `vehicle_type != 'ev'` | Excludes already-converted drivers |
| Recent data | `trip_date >= CURRENT_DATE - 90` | Scoring must reflect current behaviour, not stale data |

### 2.2 Tier assignment

Within the eligible pool, drivers are ranked into three tiers based on how closely their behaviour matches a natural EV use case.

| Tier | Label | What it means |
|---|---|---|
| Tier 1 | High-value conversion target | Strong multi-signal behavioural case for EV; highest conversion probability |
| Tier 2 | Mid-value, worth nurturing | Partial signal; likely to convert with lighter support |
| Tier 3 | Awareness only | Insufficient current signal; referral and information only |

**Tier 1 eligibility criteria** (all four must be met):

```
avg_trip_dist_km  <= 12     -- trips well within EV range
city_centre_share >= 0.60   -- operates in zones with charging access
avg_daily_trips   >= 8      -- high daily utilisation; EV economics stack up
tenure_months     >= 6      -- enough platform history to score reliably
```

**Tier 2 eligibility criteria** (all four must be met; not already Tier 1):

```
avg_trip_dist_km  <= 18
city_centre_share >= 0.45
avg_daily_trips   >= 5
tenure_months     >= 3
```

**Tier 3:** All remaining active non-EV drivers who pass the baseline filter.

### 2.3 Threshold sensitivity

These thresholds are starting points, not permanent rules. They should be adjusted based on actual driver distribution in each city:

| Threshold | Loosen to… | Effect |
|---|---|---|
| `avg_trip_dist_km <= 12` | `<= 18` | Expands Tier 1 by ~40%; appropriate for cities with better charging density |
| `city_centre_share >= 0.60` | `>= 0.45` | Brings in suburban markets where charging is improving |
| `avg_daily_trips >= 8` | `>= 10` | Tightens to highest-utilisation drivers only; reduces volume but improves conversion rate |
| `tenure_months >= 6` | `>= 3` | Appropriate if the driver base skews newer |

---

## 3. Behavioural signals and what they reveal

Each signal is a proxy for a specific suppressed intent pattern. Matching the incentive to the signal — not applying a blanket subsidy — is what makes targeting efficient.

### 3.1 Natural EV profile

**Signal:**
```
avg_trip_dist_km  <= 12  AND  city_centre_share >= 0.60
```

**What this reveals:** This driver's current trips are already well within EV range, and they operate in zones where charging infrastructure exists or is being built. The economics of an EV work for them today. The barrier is information, not capital — they do not know that their routes are EV-compatible.

**Appropriate lever:** Charging finder feature. No cash subsidy needed. Show this driver exactly where chargers are on their usual routes, and conversion likelihood is high.

---

### 3.2 Financial motivation signal

**Signal:**
```
avg_daily_trips >= 8  AND  peak_hour_share >= 0.50
```

**What this reveals:** This driver earns the majority of their income during peak hours and runs a high daily trip volume. Their primary fear about switching to EV is not upfront cost — it is the risk of earning less during a transition period (unfamiliar vehicle, charging pauses, route learning curve). An earnings floor removes that risk.

**Appropriate lever:** Earnings guarantee (daily floor for 60–90 days post-switch). The driver's economics are already strong; the incentive just removes the downside scenario that is stopping them from committing.

---

### 3.3 Cash-constrained / loan candidate signal

**Signal:**
```
tenure_months >= 24  AND  vehicle_age_yrs >= 4
```

**What this reveals:** A driver who has been on the platform for 2+ years and has not upgraded a vehicle that is 4+ years old is almost certainly capital-constrained, not intent-constrained. They have the tenure to demonstrate platform commitment and the motivation to switch, but cannot finance the EV upfront. The lock-in is access to capital.

**Appropriate lever:** 0% interest EV loan tie-up, structured so the platform subsidy serves as the down payment. This is the unlock — not a cash grant, which would be smaller and less effective for this profile.


---

## 4. Sub-segment overlap and incentive stacking

Drivers frequently match more than one signal. Stacking rules prevent budget waste and conflicting offers.

| Overlap | Rule |
|---|---|
| Natural EV profile + cash-constrained | Loan tie-up is primary lever; charging finder is additive at no extra cost |
| Financially motivated + Tier 1 eligible | Driver can choose: enhanced earnings guarantee OR cash subsidy — not both. Present as a choice at application |
| Cash-constrained + Tier 1 eligible | Loan tie-up is in addition to cash subsidy; subsidy acts as down payment |

---

## 5. Rollup output and budget allocation

The SQL query (`ev_driver_cohort.sql`) produces a **city × tier rollup** with sub-segment counts. This is the direct input to incentive budget sizing.

| Column | Use |
|---|---|
| `driver_count` | Total addressable pool per tier per city |
| `natural_ev_fit` | Count who need charging finder only — near-zero marginal cost |
| `peak_earners` | Count who need earnings guarantee — cost is a function of shortfall, not a fixed grant |
| `loan_candidates` | Count who need loan tie-up — requires lending partner capacity planning |
| `avg_trip_dist_km` | Validates tier assignment; flags if a city's Tier 1 has higher-than-expected distances |
| `avg_city_centre_pct` | Proxy for local charging infrastructure relevance |

Budget is allocated at the sub-segment level, not the tier level. A city with a large `natural_ev_fit` count in Tier 1 should spend almost nothing on cash subsidies for that sub-segment — the product feature is the incentive.

---

## 6. Schema dependency

The scoring logic depends on four tables. Any data quality issues in these tables will degrade tier accuracy.

| Table | Critical column | Risk if missing or dirty |
|---|---|---|
| `drivers` | `vehicle_type`, `onboarding_date`, `vehicle_year` | Incorrect tier assignment; EV drivers included in targeting |
| `trips` | `avg_dist_km`, `city_centre_pct`, `peak_hour_pct`, `trip_count` | All three primary signals are computed from this table |
| `charging_events` | `charge_location` | Needed for hub placement analysis; not used in scoring |


## 7. What this PRD does not cover

- Charging infrastructure build-out 
- In-app charging finder UX and feature spec
- OEM and lending partner agreements for the loan tie-up
- Rider-facing EV preference features
- Fleet procurement

These are downstream of cohort identification. Getting the cohort and signal-to-incentive matching right is the prerequisite for all of them.
