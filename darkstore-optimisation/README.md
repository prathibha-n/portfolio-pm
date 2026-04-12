# Dark Store Slot-Utilisation Dashboard
**PIN 560068 — Bellandur, Bengaluru**

---

## The thought process

### What's the actual problem?

A dark store in Bellandur has 8 pickers. They're rostered the same way at 11am as at 7pm. Nobody knows if that's right. Orders don't arrive at a flat rate — they spike in the morning, crater at noon, surge hard in the evening, and go quiet overnight. The roster doesn't know this. The manager doesn't have a number in front of them that says "right now, 5 of your 8 pickers have nothing to do."

So the first question was: **how bad is the waste, exactly?**

---

### How do you measure waste you can't see?

You need a definition first. We said: a picker slot is wasted when it's running below 40% utilisation — meaning the picker is idle for more than 36 minutes of every hour. Below that threshold, the buffer value of keeping them active doesn't justify the cost.

Once you have that definition, the question becomes a data question. How many hour-day combinations fall below that line? What does that cost in rupees? The answer was uncomfortable: **145 out of 168 possible hour-day slots are underutilised, costing roughly ₹4.9 lakh a month in idle labour.**

---

### OK so we know it's bad. What do we actually do about it?

Knowing waste exists isn't enough. A manager can't act on "your store is 62% utilised." They need to know: *which slots, which hours, how many to reduce, and what does that save?*

That meant producing a ranked action list — take the worst offenders, compute how many slots to remove conservatively, and give the manager something they can action in tomorrow morning's briefing. The overnight window from 01:00–05:00 is the obvious first move: near-zero demand, near-zero SLA risk, and consistent every single day of the week.

---

### But if we reduce slots during quiet hours, won't we get caught out when demand spikes?

Yes — and this is the risk that almost got ignored. If a manager follows the reallocation list without knowing what demand is coming tomorrow, they could reduce overnight slots on a night that happens to precede a Diwali rush or a pay-cycle spike. That's how you create the very SLA problem you were trying to solve.

So the waste analysis and the demand forecast can't be two separate tools. They have to live on the same screen. **That's why the forecast exists** — not as a standalone ML exercise, but as the guardrail that makes the waste recommendations safe to act on.

---

### What does a good forecast look like here?

We needed something that understands Bengaluru demand specifically — not just weekly seasonality, but Indian holidays, the mid-month lull, the pay-cycle surge at month-start and month-end. A plain ARIMA model doesn't know what Ugadi is.

We ran two models — SARIMA and Prophet — and evaluated both honestly on 14 days of data the models never saw during training. Prophet won (MAPE 5.6% vs 6.5%), largely because it could incorporate the holiday calendar. The 7-day forecast is what feeds both the dashboard and the restocking trigger in the A/B test.

---

### How do we know when the ML restocking trigger actually works?

We don't — until we test it. The current process is: restock when stock drops below a fixed number. The proposed process is: restock when forecasted demand in the next 4 hours is likely to exceed current stock.

These two approaches will produce different stockout rates. The A/B test randomises at the SKU level — some products get the ML trigger, others stay on the manual threshold — and measures whether stockout rate drops by at least 2.5 percentage points. That's the minimum effect size that would justify rolling this out across every SKU in every store.

---

### How do we actually ship this?

The PRD sequences the rollout so that the easiest, highest-confidence action — the overnight roster reduction — happens in Week 5, before the full dashboard is even live. That generates immediate savings and gives Finance a clean before/after comparison to prove the analysis is real.

The A/B test runs in weeks 6–8. Expansion to Koramangala, Whitefield, and Indiranagar happens in week 9 — but only if wasted labour cost has dropped by 40% and SLA breach rate hasn't gotten worse. Both conditions matter. Saving money by breaking delivery promises is not a win.

---

## Files

| File | What it answers |Link|
|---|---|---|
| `01_sql_schema_queries.sql` | How do we structure and query the underlying store data? |[Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/01_sql_schema_queries.sql)
| `02_demand_forecast.ipynb` | How bad is the waste? What will demand look like next week? | [Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/02_demand_forecast_1.ipynb)
| `02_7day_forecast.csv` | The forecast output, ready for the dashboard or WMS to consume | [Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/02_7day_forecast.csv)
| `02_demand_forecast_charts.png` | Visual proof of model accuracy and demand patterns |
| `03_PRD.md` | What are we building, why, and how do we know it worked? | [Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/03_PRD.md)
| `04_AB_test_design.md` | How do we prove the ML restocking trigger is better than manual? |[Link](https://github.com/prathibha-n/portfolio-pm/blob/main/darkstore-optimisation/04_AB_test_design.md)
