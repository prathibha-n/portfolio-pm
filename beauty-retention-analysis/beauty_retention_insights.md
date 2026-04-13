# Beauty Ecommerce — Retention Cohort Insight Doc

**Dataset:** 5,000 simulated users | Sep 2024 – Feb 2025 | 5 categories | 5 acquisition channels  
**Analysis:** D7 / D30 / D90 retention by signup cohort, acquisition channel, and first-order category

---

## Headline Numbers

| Window | Overall Retention |
|---|---|
| D7  | 15.7% |
| D30 | 24.7% |
| D90 | 22.5% |

The first thing to notice is that **D30 retention is higher than D7 retention across the board**. In most ecommerce categories this would be unusual — you'd expect a monotonic decay. In beauty, it's structural. Products run out in roughly 30 days, not 7. The business implication: D7 is not the right primary retention metric for this vertical. D30 is.

---

## Insight 1 — The Replenishment Cycle is ~30 Days, Not ~7

The overall D30 retention of 24.7% vs D7 of 15.7% (+9pp gap) reflects a category-level truth: **beauty products are consumed, not used once**. A moisturiser, a serum, a shampoo — these run out. Customers come back not because of a campaign but because the product is gone.

This has a direct implication for how retention is measured and optimised. A D7 re-engagement push sent to a skincare customer is structurally too early — the product is not yet empty, the need has not yet been created. Sending it anyway trains users to ignore notifications.

**The retention window to optimise for is D20–27** — just before the product runs out, not after.

---

## Insight 2 — Category Strategy Cannot Be One-Size-Fits-All

The four categories behave fundamentally differently across two dimensions: **intent at acquisition** and **replenishment behaviour**.

| Category | D7 | D30 | D30 minus D7 | Behaviour type |
|---|---|---|---|---|
| Health & Beauty | 18.5% | 32.6% | +14.0pp | High intent, high repeat |
| Personal Care | 14.7% | 23.4% | +8.7pp | High intent, stocking behaviour |
| Haircare | 15.2% | 23.4% | +8.2pp | High intent, moderate repeat |
| Makeup | 13.8% | 17.4% | +3.6pp | Low intent, impulse-driven |
| Fragrance | 11.7% | 13.6% | +1.9pp | High intent, durable product |

### Health & Beauty — the retention engine
The highest D30_minus_D7 gap of any category (+14pp) combined with consistent D30 retention above 40% via Google Search and Referral Program makes this the core replenishment category. Google Search × Health & Beauty specifically delivers D30 = 41.1% — the single strongest segment in the dataset. This is the category to build subscription and replenishment infrastructure around first.

### Haircare & Personal Care — stocking behaviour complicates timing
Both categories show healthy D30 retention via Google Search and Referral channels but a smaller replenishment gap than Health & Beauty. The reason is not a longer product cycle — it is stocking behaviour. A customer who buys 3 shampoos in one order will not need to restock for 60–90 days. A fixed-day nudge (e.g. contact everyone at day 25) will misfire for this segment.

**The right trigger here is consumption-based, not calendar-based.** Quantity purchased at first order should be used to derive an estimated restock date per user. Buy 1 unit → nudge at day 25. Buy 3 units → nudge at day 75. This requires order quantity tracking but produces far less notification fatigue.

### Makeup — do not chase replenishment
Makeup has the flattest retention curve in the dataset. D30 = 17.4%, D90 = 17.0% — nearly identical, no replenishment signal. The primary acquisition channel is Instagram / Meta Paid, which produces the lowest retention of any channel (D30 = 15.8%). This is structurally impulse-driven behaviour: a user sees a viral product in a scroll, clicks, buys, does not return.

Sending replenishment nudges to Makeup buyers is wasted spend. The re-engagement strategy for this segment should be **newness and trend-led** — not "your product is running out" but "this new shade just dropped" or "this is trending right now." Lean into the same FOMO mechanic that acquired them.

### Fragrance — long cycle, occasion-led
Fragrance shows the smallest D30_minus_D7 gap (+1.9pp) and near-flat retention across all windows (D7 = 11.7%, D30 = 13.6%, D90 = 15.5%). This is consistent across all acquisition channels — it is not a channel problem, it is a product durability problem. A fragrance lasts 6–12 months, not 30 days.

The re-engagement strategy here is **occasion and gifting-led** — festive season nudges, birthday reminders, "gift for someone" prompts. Replenishment messaging is structurally wrong for this category.

---

## Insight 3 — Channel Quality Varies Enormously and Scaling is Non-Linear

| Channel | D30 Retention | Nature of acquisition |
|---|---|---|
| Referral Program | 35.4% | Trust + social proof |
| Google Search | 30.1% | High intent, active search |
| App Organic | 25.6% | Moderate intent |
| Influencer & Creator | 21.0% | Aspiration-driven, moderate intent |
| Instagram / Meta Paid | 15.8% | Impulse, low intent |

### Referral Program — highest retention but cannot be forced
Referral buyers retain at 35.4% D30 — more than double Instagram / Meta Paid. The signal is trust: someone bought because a person they know recommended it, not because an algorithm served them an ad. Referral Program × Health & Beauty in particular shows D30 retention between 43–58% across cohort months.

However, **Referral cannot be scaled by throwing money at it**. Incentivising referrals aggressively (e.g. ₹200 off for every friend referred) shifts the user base from genuine advocates to coupon hunters. The trust signal — which is the entire reason retention is high — degrades as the mechanic becomes transactional. Referral should be nurtured and made easy, not force-multiplied.

### Google Search — the scalable high-intent channel
Google Search delivers D30 = 30.1% overall and 41.1% for Health & Beauty specifically. Unlike Referral, it can be scaled through spend without corrupting the intent signal — a user who searches "best vitamin C serum under 500" is actively in-market regardless of whether one or ten thousand people do so simultaneously.

**This is the channel to increase acquisition investment in**, particularly targeted toward Health & Beauty and Personal Care category keywords where the replenishment cycle is most predictable.

### Instagram / Meta Paid — right channel, wrong category
Instagram / Meta Paid is not a bad channel — it is being used for the wrong categories. Its low overall retention (15.8% D30) is heavily dragged down by Makeup, where FOMO-driven impulse purchases produce near-zero repeat intent. The same channel targeting Health & Beauty produces D30 = 18–28% depending on cohort — still below Google Search but meaningfully higher than Makeup via the same channel.

**Recommendation:** shift Instagram / Meta Paid budget away from Makeup acquisition and toward Health & Beauty and Haircare. Use it for Makeup only for new product launches and trend moments — not as a steady-state retention channel.

---

## Insight 4 — Lifecycle Segmentation Requires Different Metrics Per Stage

Treating all returning customers the same is the most common retention mistake. The data supports three distinct lifecycle stages, each requiring a different strategy and a different success metric.

| Stage | Definition | Goal | Success metric |
|---|---|---|---|
| **New** | First purchase, <30 days | Get the second purchase | D30 repeat purchase rate |
| **Returning** | 2nd or 3rd purchase | Expand the basket | Adjacent category attach rate + basket size |
| **Veteran** | 3+ purchases, established cycle | Lock in the habit | Subscription conversion rate + AOV |

### New users — the only job is the second purchase
For a user who has just made their first purchase, the entire retention strategy should focus on one thing: do they buy again within 30 days? No cross-sell, no upsell, no product discovery push yet. The second purchase is the proof of intent. Without it, the customer is still a one-time buyer.

In addition to the replenishment nudge at day 20–27, New users benefit from light discovery — "here's what else works with what you bought" — to signal catalogue breadth without overwhelming.

### Returning users — basket expansion
A user who has made their second purchase has demonstrated replenishment intent. This is the right moment to introduce adjacent products. The framing should feel natural and complementary — a shampoo buyer shown a hair mask, a moisturiser buyer shown a sunscreen. Cross-sell effectiveness is highest when it follows the logic of the customer's existing routine rather than the business's margin priorities.

### Veteran users — subscription conversion
A user on their third or fourth replenishment cycle is a subscription waiting to happen. The friction of remembering to reorder is the only barrier. A "subscribe and save" mechanic with even a modest discount (5–10%) removes that friction and converts a reliable repeater into a locked revenue stream. AOV for this segment should increase as trust in the brand enables more exploratory purchases alongside the core replenishment SKU.

---

## What to Test Next

The insights above are hypotheses derived from the cohort model. Before acting on them at scale, the following experiments should validate the key assumptions:

| Hypothesis | Test |
|---|---|
| Day 20–27 nudge outperforms day 7 nudge for Health & Beauty replenishment | A/B test nudge timing on Google Search × Health & Beauty cohort |
| Consumption-based trigger outperforms fixed-day trigger for Personal Care | Pilot on users with quantity ≥ 2 at first order vs fixed-day control |
| Instagram / Meta Paid shifted to Health & Beauty improves channel D30 | Reallocate 20% of Makeup budget to Health & Beauty for 60 days, compare D30 retention of new cohort vs historical baseline |
| Referral incentive above threshold degrades trust signal | Test ₹100 vs ₹300 referral reward, measure D90 retention of referred users |

**Critical note on measurement:** reactivated users always look profitable in naive analysis because the counterfactual — would they have purchased anyway? — is invisible without a holdout group. Every re-engagement experiment above requires a control group that receives no intervention. The delta in GMV between the nudged group and the control group, not total GMV from re-engaged users, is the correct success metric.

---

*Analysis based on synthetic dataset mirroring Olist ecommerce schema. Retention coefficients documented in `beauty_retention_cohort.ipynb` Step 3.*
