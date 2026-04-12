# PRD — Ridehailing EV Transition (India): Incentive Design & Charging Finder

**Product area:** Driver Platform — Electrification & Charging  
**PM owner:** PM II, Electrification & Charging  
**Applicable platforms:** Uber India, Rapido, Ola, Porter, and any ridehailing or gig-mobility operator with a driver fleet in Indian metros  
**Status:** Draft v1.0  
**Last updated:** April 2026  

---

## 1. Problem statement

The platform's path to a zero-emissions fleet is blocked not by driver resistance to EVs, but by three discrete, addressable barriers:

1. **Capital barrier** — upfront EV cost is prohibitive for drivers who are cash-constrained despite strong daily earnings.
2. **Infrastructure anxiety** — drivers fear being stranded mid-shift without a nearby charger, even on routes where EV range is more than sufficient.
3. **Information gap** — drivers do not have a reliable, real-time view of charging availability integrated into their workflow.

A driver who averages 10 km per trip, operates 70% in city-centre zones, and has been on the platform for 4+ years has a textbook EV use case. The economics work. The behaviour fits. The barrier is perception and access — both of which are product problems.

---

## 2. Goals

| Goal | Metric | Target (12 months) |
|---|---|---|
| Grow EV share of active fleet | EV % of active driver fleet | 15% (from baseline) |
| Reduce dead-battery cancellations | Dead-battery cancel rate | <0.5% of accepted trips |
| Drive EV activation in Tier 1 cohort | EV activation rate at D30 | >40% of Tier 1 outreach |
| Retain converted EV drivers | D90 EV driver retention | >80% |
| Validate incentive efficiency | Cost per EV conversion | <₹22,000 blended |

### Non-goals

- This PRD does not cover fleet procurement or OEM partnerships (handled by BD team).
- This PRD does not cover rider-facing EV preference features.
- Charging infrastructure build-out is owned by the City Ops team; this PRD covers the in-app discovery layer only.

---

## 3. Target users

Defined by the SQL cohort query (see `ev_driver_cohort.sql`). Three sub-segments within the addressable pool, each with a distinct primary barrier and incentive lever:

| Sub-segment | Flag | Primary barrier | Incentive lever |
|---|---|---|---|
| Natural EV profile | `natural_ev_profile = TRUE` | Information gap — doesn't know charging is accessible on their routes | Charging finder feature; no cash needed |
| Peak earner | `financially_motivated = TRUE` | Earnings uncertainty during EV transition period | Earnings guarantee for 90 days |
| Cash-constrained | `likely_cash_constrained = TRUE` | Cannot finance EV upfront despite strong payback economics | 0% interest EV loan tie-up |

Drivers can belong to more than one sub-segment. Incentive stacking rules are defined in Section 5.

---

## 4. User stories

### 4.1 Driver considering EV switch

> **As a** petrol driver who has been on the platform for 4+ years,  
> **I want to** understand exactly what financial support is available and how much I will earn in the first 90 days on an EV,  
> **so that** I can make a confident switch decision without risking my livelihood.

**Acceptance criteria:**
- Driver can view their personalised incentive offer (tier-specific) from the home screen of the driver app.
- Offer card shows: subsidy amount, loan EMI estimate, 90-day earnings floor, and estimated fuel savings per month.
- Driver can complete the EV transition application in ≤5 taps from the offer card.
- Application confirmation is shown within 24 hours.

---

### 4.2 Driver experiencing range anxiety mid-shift

> **As an** EV driver with 20% battery remaining who has just accepted a trip,  
> **I want to** know immediately whether I can complete this trip and still reach a charger without going below 10%,  
> **so that** I do not have to cancel and lose earnings.

**Acceptance criteria:**
- Battery status widget is visible on the trip acceptance screen when battery ≤ 25%.
- Widget shows: estimated battery % on trip completion, nearest fast-charger name and ETA, and whether the charger is currently available.
- If completion battery would drop below 15%, the app proactively suggests a charger waypoint.
- Driver can add charger waypoint in one tap without cancelling the trip.

---

### 4.3 Driver planning their shift around charging

> **As an** EV driver starting a shift,  
> **I want to** see which fast-chargers are near my usual operating area and check live slot availability,  
> **so that** I can plan a charging stop between trips without dead time.

**Acceptance criteria:**
- Charging finder is accessible from the driver app home screen within 2 taps.
- Map shows all chargers within a configurable radius (default 3 km) filtered by connector type matching driver's vehicle.
- Each charger shows: distance, ETA, number of available slots (live), connector types, and average wait time (last 7 days).
- Driver can set a "charge reminder" that pings them when battery drops below a threshold they define (default 30%).

---

### 4.4 Driver who was declined for Tier 1 incentive

> **As a** driver who does not yet qualify for Tier 1 incentive,  
> **I want to** understand what I need to do to qualify,  
> **so that** I have a clear path to accessing the full subsidy.

**Acceptance criteria:**
- Drivers in Tier 2 and Tier 3 see a "Your progress to Tier 1" card showing which criteria they meet and which they don't.
- Card updates weekly based on rolling 90-day trip data.
- Drivers in Tier 3 who cross into Tier 2 receive an in-app notification within 48 hours.

---

## 5. Incentive tier logic

### Tier structure

| Tier | Eligibility | Cash subsidy | Earnings guarantee | Loan tie-up | Priority queue boost |
|---|---|---|---|---|---|
| **Tier 1** | `avg_trip_dist_km ≤ 12` AND `city_centre_share ≥ 0.6` AND `avg_daily_trips ≥ 8` AND `tenure_months ≥ 6` | ₹15,000 | ₹1,200/day floor for 90 days | Yes — 0% interest, 36-month term | Yes — +15% trip allocation score |
| **Tier 2** | `avg_trip_dist_km ≤ 18` AND `city_centre_share ≥ 0.45` AND `avg_daily_trips ≥ 5` AND `tenure_months ≥ 3` | ₹8,000 | ₹900/day floor for 60 days | Yes — 4% interest, 36-month term | Yes — +8% trip allocation score |
| **Tier 3** | All others | None | None | None | EV test-drive access + ₹500 referral bonus per convert |

### Stacking rules

- A driver flagged `likely_cash_constrained` who qualifies for Tier 1 receives the loan tie-up **in addition to** the cash subsidy, not instead of it. The subsidy serves as the down payment.
- A driver flagged `financially_motivated` who qualifies for Tier 1 can **opt for** an enhanced earnings guarantee (₹1,400/day floor for 90 days) in lieu of the ₹15,000 cash subsidy — not both. The choice is presented at application.
- The priority queue boost activates on the date the driver completes their first EV trip, not on application approval.
- Earnings guarantee payments are made weekly in arrears. If actual earnings exceed the floor, no top-up is paid. The guarantee only covers shortfall.

### Clawback policy

- If a driver exits the platform within 6 months of receiving a Tier 1 or Tier 2 subsidy, 50% of the cash subsidy is recovered from their final settlement.
- Clawback does not apply to earnings guarantee payments already disbursed.
- Clawback terms are shown explicitly on the offer card and require driver acknowledgement before application.

---

## 6. Charging finder — feature spec

### 6.1 Data layer

| Data source | Update frequency | Owner |
|---|---|---|
| Charger location and connector types | Weekly sync | City Ops / OEM partners |
| Live slot availability | Real-time via OCPI API | Charging network operators (Tata Power, BPCL, Ather Grid) |
| Historical wait time | Rolling 7-day average, computed nightly | Data Engineering |
| Driver vehicle connector type | Set at EV onboarding | Driver Platform |

### 6.2 Surface points

The charging finder is not a standalone screen. It surfaces contextually at three points:

**Surface 1 — Trip acceptance screen (battery ≤ 25%)**  
A compact banner below the trip details showing nearest available charger, ETA, and current slot count. One-tap to add as waypoint.

**Surface 2 — Between-trip idle state**  
When driver is online but has no active trip and battery ≤ 35%, a card appears suggesting the two nearest fast-chargers with live availability. Dismissable.

**Surface 3 — Finder tab (proactive planning)**  
Accessible from home screen. Full map view with filters: connector type, charger speed (fast/slow), distance radius, availability now vs. available soon. Driver can save up to 3 favourite chargers.

### 6.3 Battery-anxiety UX intervention — escalation ladder

Triggered when `battery_pct ≤ 25%` and driver has an active or recently accepted trip.

| Level | Trigger | Intervention | Driver action required |
|---|---|---|---|
| L1 — Soft nudge | Battery ≤ 25%, trip accepted | Banner: "Nearest charger 4 min away — complete this trip first?" | Dismiss or tap to view |
| L2 — Route insert suggestion | Projected end-of-trip battery ≤ 15% | App suggests adding charger as waypoint; shows impact on ETA (+N min) | Accept or decline waypoint |
| L3 — Demand pause | Battery ≤ 10% | New trip pings suppressed until battery ≥ 40%; driver sees countdown and nearest charger | Navigate to charger |

L3 is the only non-optional intervention. Suppressing trip pings below 10% is a guardrail against the dead-battery cancellation metric — a driver who accepts a trip at 8% battery and cancels en route is worse for the platform than a driver who charges first.

### 6.4 Connector type filtering logic

Driver's connector type is stored at EV onboarding. The finder filters by default to show only compatible chargers. Driver can override the filter to see all chargers (useful when they have an adapter). Incompatible chargers are shown greyed out with a "not compatible" label rather than hidden — this prevents confusion when a driver sees a charger physically but can't find it in the app.

---

## 7. Out-of-scope edge cases to resolve before launch

| Edge case | Question | Recommended resolution |
|---|---|---|
| Driver switches to EV mid-experiment window | Are they eligible for incentive if they weren't in the treatment group? | Intent-to-treat: eligibility is based on cohort membership at experiment start, not activation date |
| Driver qualifies for Tier 1 but has existing vehicle loan | Does the 0% loan tie-up work alongside existing finance? | Defer to lending partner; surface a "check eligibility" CTA rather than a direct offer |
| Charger shown as available but actually occupied | Live OCPI data has ~5 min lag | Show "last updated X min ago" timestamp on slot count; set driver expectation |
| Driver declines EV switch after viewing offer | How long before they see the offer again? | 30-day suppression on the offer card; do not re-surface aggressively |
| Earnings guarantee floor not met due to driver going offline voluntarily | Does the guarantee apply? | No — guarantee only covers platform-side demand shortfall, not driver-side inactivity. Defined in T&Cs. |

---

## 8. Metrics and instrumentation

### Primary metrics
- `ev_fleet_pct` — EV drivers as % of weekly active drivers, by city
- `dead_battery_cancel_rate` — battery-related cancels as % of accepted trips, EV fleet only

### Secondary metrics
- `ev_activation_rate_d30` — % of Tier 1 outreach who complete first EV trip within 30 days
- `ev_retention_d90` — % of activated EV drivers still active at 90 days
- `cost_per_conversion` — total incentive spend / activated EV drivers

### Leading indicators (weekly)
- Offer card impression → application start rate
- Application start → submission rate
- Charging finder opens per EV driver per week
- L2 waypoint acceptance rate (proxy for anxiety reduction)
- L3 demand pause events per 1,000 EV trips (should decline as fleet matures)

### Instrumentation requirements
- All offer card interactions (impression, tap, application start, application submit) logged with `driver_id`, `ev_tier`, `incentive_variant`, `timestamp`
- Charging finder: log surface point, charger selected, waypoint added (Y/N), session duration
- Battery anxiety ladder: log level triggered, driver action taken, outcome (trip completed / cancelled / redirected to charger)

---

## 9. Launch sequencing

| Phase | Scope | Duration | Success gate |
|---|---|---|---|
| Phase 0 — finder soft launch | High-anxiety cohort only (`battery_cancel_rate > 5%`, all tiers) — ~951 drivers, BLR only | 3 weeks | Finder weekly active usage > 60% of cohort; dead-battery cancel rate drops ≥ 20% |
| Phase 1 — incentive pilot | Tier 1 cohort, BLR only — ~1,840 drivers, randomised A/B (cash vs earnings guarantee) | 6 weeks | EV activation rate > 35%; cost per conversion < ₹25,000 |
| Phase 2 — city expansion | Tier 1 + Tier 2, BLR + DEL + MUM | 8 weeks | Blended cost per conversion < ₹22,000; D90 retention > 80% |
| Phase 3 — full rollout | All tiers, all 5 cities | Ongoing | `ev_fleet_pct` > 15% |

Phase 0 is the critical gate. Launching the charging finder to the high-anxiety cohort before any cash spend tests whether the information gap alone — not the capital barrier — is the binding constraint for a meaningful subset of drivers. If finder engagement reduces their cancel rate by ≥20%, that is evidence the conversion funnel can be moved with zero subsidy for this sub-segment.

---

## 10. Open questions

1. Does the earnings guarantee require RBI compliance review given it functions as a minimum income guarantee? Flag for Legal before Phase 1.
2. What is the OEM partner list for the 0% loan tie-up, and what is their approval SLA? Needs BD confirmation before offer card copy is finalised.
3. Is OCPI API integration with all three charging networks (Tata Power, BPCL, Ather Grid) complete, or is Phase 0 limited to one network?
4. How does the priority queue boost interact with existing surge and allocation algorithms? Needs alignment with the Marketplace PM.
