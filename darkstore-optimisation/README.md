# Dark Store Slot-Utilisation Dashboard
**PIN 560068 — Bellandur, Bengaluru**

> **Note:** This project runs on a simulated dataset. I didn't have access to real order data from the Bellandur store. The demand patterns, utilisation numbers, and cost figures are modelled from publicly known quick-commerce behaviour in Bengaluru — illustrative of what the analysis *would* surface, not a report on what *has* been found.

---

## The thought process

### What's the actual problem?

A dark store in Bellandur has 8 pickers. The assumption — grounded in how dark stores generally operate — is that they're rostered the same way at 11am as at 7pm, because that's the default when scheduling isn't data-driven. Orders don't arrive at a flat rate. They spike in the morning, crater at noon, surge hard in the evening, and go quiet overnight. A fixed roster doesn't account for any of that.

First question: **if the data existed, how bad might the waste be?**

---

### How do you measure waste you can't see?

Before touching any data — real or simulated — a definition is needed. I settled on: a picker slot is wasted when it's running below 40% utilisation, meaning the picker is idle for more than 36 minutes of every hour. Below that threshold, the buffer value of keeping the slot active doesn't justify the cost.

With that set, I simulated 6 months of hourly order data around known Bengaluru demand patterns: the morning milk-and-bread spike, the evening dinner surge, the weekend uplift, the pay-cycle bump at month-start and month-end. Running the waste calculation on that produced a number that, if it reflected reality, would be uncomfortable: **roughly 145 out of 168 hour-day combinations falling below threshold, implying around ₹4.9 lakh a month in idle labour cost.**

That's not a finding — it's a hypothesis about the scale of the problem, designed to show what this analysis *would* look like with real data plugged in.

---

### The simulation suggests it's bad. What would actually be done about it?

A manager can't act on "your store is probably 62% utilised." They need: *which slots, which hours, how many to reduce, and what does that save?*

The notebook produces a ranked action list from the simulated data — the worst offenders, a conservative estimate of how many slots to remove, and a weekly saving figure. In the simulation, the overnight window from 01:00–05:00 is the obvious first move: near-zero demand, near-zero SLA risk, consistent across every day of the week. With real data, the shape might differ — but the method for finding it would be identical.

---

### But reducing slots during quiet hours risks getting caught out when demand spikes.

Exactly — and this is the tension I almost missed in the design. A manager following the reallocation list without knowing what demand is coming tomorrow could reduce overnight slots on a night that precedes a Diwali rush or a pay-cycle spike. That's how you create the very SLA problem you were trying to solve.

**That's the real reason the forecast exists in this project** — not as a standalone ML exercise, but as the guardrail that makes the waste recommendations safe to act on. The waste analysis and the forecast have to live on the same screen. The simulation makes this constraint visible even without real data.

---

### What does a good forecast look like here?

The model needed to understand Bengaluru demand specifically — not just weekly seasonality, but Indian holidays, the mid-month lull, the pay-cycle surge. A plain ARIMA model doesn't know what Ugadi is.

I trained two models — SARIMA and Prophet — and evaluated both on 14 held-out days neither saw during training. Prophet won (MAPE 5.6% vs 6.5%), largely because it could incorporate the holiday calendar as explicit features. Those accuracy numbers are a product of the simulation's own patterns, so they reflect best-case conditions. Real data would be noisier — but the methodology for evaluation, and the reason Prophet is the right choice here, holds regardless.

---

### How do you know when the ML restocking trigger actually works?

You don't — until it's tested on real data with real stakes. The assumed current process is: restock when stock drops below a fixed number. The proposed process is: restock when forecasted demand in the next 4 hours is likely to exceed current stock.

The A/B test design is written as if this experiment is about to run, because the design itself is the deliverable — it shows how to structure the test, what sample size is needed, what metric is primary, and what decision gets made based on the result. The 2.5 percentage point minimum detectable effect and the 28-day timeline are real choices that would apply directly to a real experiment.

---

### How would this actually ship?

The PRD is written in the present tense because that's how product documents work — they describe what's going to happen, not what has. The sequencing is deliberate: the overnight roster reduction comes in Week 5, before the full dashboard is live, because it's the action with the clearest signal and lowest risk. It also creates the before/after comparison that would let Finance validate the methodology against real numbers for the first time.

Everything from Week 6 onward — the A/B test, the expansion to Koramangala and Whitefield — is contingent on what those real numbers say. The simulation gets you to the starting line. It doesn't cross it for you.

--
## Files

| File | What it answers |Link|
|---|---|---|
| `01_sql_schema_queries.sql` | How do we structure and query the underlying store data? |[Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/01_sql_schema_queries.sql)
| `02_demand_forecast.ipynb` | How bad is the waste? What will demand look like next week? | [Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/02_demand_forecast_1.ipynb)
| `02_7day_forecast.csv` | The forecast output, ready for the dashboard or WMS to consume | [Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/02_7day_forecast.csv)
| `02_demand_forecast_charts.png` | Visual proof of model accuracy and demand patterns |
| `03_PRD.md` | What are we building, why, and how do we know it worked? | [Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/03_PRD.md)
| `04_AB_test_design.md` | How do we prove the ML restocking trigger is better than manual? |[Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/04_AB_test_design.md)
