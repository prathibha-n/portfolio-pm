# Cancellation risk model — design rationale

## What the model is measuring

Battery cancel rate is a proxy for suppressed EV intent — not just a service quality metric. A driver who cancels due to low battery has already accepted the trip, meaning they are willing to work but the infrastructure failed them. This is distinct from a driver who never accepts trips in the first place.

---

## Three signals, three uses

### Signal 1 — `battery_cancel_rate`

Rate of battery-related cancels among accepted trips. The accepted-trip denominator is critical — it filters out laziness cancels and isolates infrastructure-driven drops. Used to flag `high_battery_anxiety = TRUE` at >5%. These drivers get priority outreach in the incentive campaign.

### Signal 2 — `daily_km_proxy`

`avg_daily_trips × avg_trip_dist_km`. This is the economic payback signal for Uber. A driver doing 100 km/day on petrol is spending ~₹400/day in fuel. EV equivalent ~₹80/day. That ₹320/day saving closes the EV loan in <18 months — the pitch writes itself. Used to rank within a tier.

### Signal 3 — `city_centre_share`

Share of trips in central zones. City-centre drivers have shorter trip distances (ideal for current EV range), are more likely to be near fast-charger hubs, and represent Uber's highest-fare density routes. Low `city_centre_share` + low `daily_km` = poor EV candidate regardless of vehicle age.

---

## Threshold sensitivity — what changes if you move the cutoffs

| Threshold change | Effect on Tier 1 pool | Trade-off |
|---|---|---|
| `vehicle_age ≥ 3` (from 4) | +40% more drivers | Includes newer vehicles that may not be ready for replacement — reduces subsidy efficiency |
| `avg_daily_trips ≥ 6` (from 8) | +55% more drivers | Lower-volume drivers have slower subsidy payback for Uber; risk of adverse selection |
| `city_centre_share ≥ 0.45` (from 0.60) | +30% more drivers | Suburban drivers have longer trips — range anxiety increases, more charging stops needed |
| `tenure_months ≥ 3` (from 6) | +15% more drivers | Newer drivers have higher platform churn rate — EV subsidy may be wasted if they leave |

---

## Total addressable cohort (illustrative)

| Segment | Driver count |
|---|---|
| Tier 1 — all cities | ~5,370 |
| Tier 2 — all cities | ~9,170 |
| High-anxiety flag (`battery_cancel_rate > 5%`) | ~951 |

---

## Key insight

The high-anxiety cohort (951 Tier 1+2 drivers with `battery_cancel_rate > 5%`) is the fastest path to early EV adoption signal. They are already experiencing range anxiety on petrol — the barrier is infrastructure knowledge, not EV resistance.

Launch the charging-station finder feature to this group first, before the full incentive rollout, and measure whether finder engagement alone reduces cancel rate. That's a zero-cost leading indicator before spending on subsidies.
