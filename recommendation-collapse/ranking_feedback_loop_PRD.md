# PRD: Ranking Feedback Loop Collapse

_Discovery & Ranking Systems — Social Commerce Platform_

_Product area: Search & Ranking  |  Domain: ML Systems + Marketplace Health_

*Status: Portfolio document — assumptions flagged throughout*

> **Exercise framing** For this exercise, I have chosen a zero-commission reseller marketplace operating in Tier 2 and Tier 3 cities in India, with micro-entrepreneur suppliers and no advertising product. This platform model is deliberate — it maximises the severity and visibility of the feedback loop problem, since organic ranking is the only distribution channel available to suppliers. All assumptions, personas, and interventions are grounded in this specific context.

# 1. Problem statement

A ranking model trained on click-through rate will, over time, learn to predict position rather than relevance. This is not a model failure — offline metrics improve. It is a data problem: clicks used as training labels carry the bias of where each item appeared. Items shown in top slots get more clicks simply because users see them first. The model reads this as a quality signal and ranks those items higher in the next cycle. Each retraining cycle makes it worse.

The consequences play out on two timescales. In the short term (weeks): new and niche suppliers get near-zero impressions, can't generate enough orders to stay active, and leave. In the medium term (months): the set of items the model actually surfaces shrinks to a small pool of historically top-ranked SKUs. Catalog diversity collapses. Queries with specific or regional intent go unserved. Conversion on long-tail queries falls silently while top-line metrics look fine — masked by strong head-query performance and new-user growth.

The damage becomes visible only when new-user growth slows and the per-user deterioration can no longer be hidden. By then, the problem is structural: churned suppliers don't return, and the model has months of bad training cycles to unwind.

> **Source** Position bias and examination probabilities: Joachims et al. (2017) 'Unbiased Learning-to-Rank from Biased Feedback', WSDM. Examination probability estimates (slot 1: ~0.95, slot 5: ~0.30, slot 10: ~0.08) are from this paper's empirical studies on web search. On mobile with a vertical scroll layout, bias is likely worse.

> **Estimate** The 60-90 day GMV lag estimate comes from: weekly retraining cadence × number of cycles for the score gap to become material (~8-12 cycles, per Joachims et al. compounding formula). 

# 2. Context & background

## 2.1 Platform model

For this exercise, I have chosen a zero-commission reseller marketplace as the platform model. Here is what that means in practice:

The platform is a zero-commission reseller marketplace targeting price-sensitive, first-time e-commerce buyers in Tier 2 and Tier 3 cities. Suppliers are micro-entrepreneurs listing fashion, home goods, and lifestyle products. They operate on thin margins with no advertising budget. Organic ranking is their only way to get visibility — there is no sponsored listings product, no preferred seller programme, no private label alternative.

This matters: on platforms with advertising products, new suppliers can pay for initial visibility to build a click history. Here, neither option exists. The feedback loop's damage is faster and harder to reverse.

## 2.2 Demand characteristics

The buyer base has two properties that make catalog collapse especially risky.   
First, demand is regionally specific — buyers in different geographies have distinct cultural, occasion-based, and aesthetic preferences that require a broad supplier pool. A catalog concentrated on nationally popular SKUs will consistently fail regional demand.   
Second, a large share of users are first-time e-commerce buyers with no purchase history, so the quality of organic ranking is the primary driver of discovery quality.

> **Estimate** Regional demand heterogeneity: inferred from the platform's geographic focus (Tier 2/3 India) and product category mix (ethnic fashion, regional home goods).
>

## 2.3 The feedback loop — plain language

Six stages, each locally rational:

| **Stage 1 — Day 0** | Model deployed on historical clicks. Assumed unbiased. |
| --- | --- |
| **Stage 2 — Position bias enters** | Users on mobile see top-slot items first and click them more — not because they are better, but because they are visible. Position contaminates the click signal. |
| **Stage 3 — Model learns the wrong thing** | Model retrains on these clicks. It cannot separate quality-driven clicks from position-driven clicks. It learns: items at the top got clicked, so items at the top are relevant. Offline AUC improves. The model is accurately predicting the wrong thing. |
| **Stage 4 — Rich-get-richer** | The retrained model scores historically top-ranked items even higher. They rank higher again. More impressions. More clicks. The score gap between visible and invisible items widens with each cycle. |
| **Stage 5 — Supplier starvation** | New suppliers get near-zero cold-start scores. They land in slots 20+. Examination probability under 2%. Expected monthly GMV is too low to justify staying active. Suppliers leave. |
| **Stage 6 — Catalog collapse** | Active catalog shrinks. Impression share concentrates on a small set of incumbents. Long-tail and regional demand goes unserved. Per-user GMV falls. Growth stalls when new-user volume can no longer hide the deterioration. |

# 3. Personas

Three actors are affected. Each experiences the problem differently and has different success criteria.

## 3.1 Buyer

| **Role** | End consumer. Tier 2/3 geography. Mobile-first. Often a first-time e-commerce user. |
| --- | --- |
| **Goals** | Find products that match specific intent — regional, occasion-based, or aesthetic. Get value for money. Complete a purchase without friction. |
| **Pain points** | Search results feel generic. The same top items appear regardless of how specific the query is. Niche or regional searches return irrelevant results. Scroll depth before finding anything relevant increases over time. |
| **Dissatisfaction signals** | Query pivot (a semantically different second search with no purchase between). Informed abandonment (scroll > 2 screens, zero clicks). Return-to-search within 14 days of a purchase. Rising scroll depth before first click, especially in Tier 2/3 geos. |
| **What they never do** | Explicitly complain that ranking is bad. Frustration shows up as absence of action. |

## 3.2 Supplier

| **Role** | Micro-entrepreneur reseller. Lists across fashion, home, lifestyle. Thin margins. No advertising budget. |
| --- | --- |
| **Goals** | Generate enough orders to cover listing effort and earn a sustainable income. Grow by expanding catalog based on what sells. |
| **Pain points** | After onboarding: near-zero impressions for weeks. No way to tell if poor performance is product quality, pricing, or invisibility. No lever to increase visibility. Rational response: list on a competing platform. |
| **Starvation signals** | Zero orders in first 14 days. No second listing after the first fails. Platform exit within 30-45 days of onboarding. |
| **What makes this persona structurally different** | Cannot buy their way out of cold-start. The platform's zero-commission promise implicitly commits to fair organic distribution. When the loop breaks that commitment, there is no fallback channel. |

## 3.3 Ranking system 

| **Role** | ML model serving ranked results across search, feed, and category pages. Retrained on click and purchase logs on a regular cadence. |
| --- | --- |
| **Stated goal** | Predict item relevance to maximise conversion. |
| **Actual behaviour under loop** | Predicts position-weighted historical click probability. Achieves improving offline AUC. Passes A/B tests. Causes catalog collapse. |
| **Why it is hard to catch** | Every metric the model is evaluated on looks healthy. Damage only shows up in catalog-level and supplier-level metrics that are not standard in an ML evaluation pipeline. |
| **What it needs** | Position-corrected training labels (IPW or DLA). An exploration budget generating uncontaminated signal on new items. Evaluation metrics that measure catalog health, not just click prediction accuracy. |

# 4. Problem decomposition

There are three things going wrong simultaneously. They feed each other, which is why the damage compounds. Fixing any one in isolation is not enough — the other two re-close the loop. All three need to be addressed.

## 4.1 The model is learning from bad data

Every time a user clicks, that click gets recorded as a signal that the item is good. But clicks are not just a function of quality — they are also a function of where the item appeared on the page. Items at the top get clicked more simply because users see them first. The model cannot tell the difference. So it learns: items that were shown at the top are good items. Next time, it ranks them even higher. They get clicked even more. The cycle repeats with every retrain.

The consequence: the model is not surfacing the best products. It is surfacing the most historically visible products. These are not the same thing, and the gap widens over time.

> **Source** Joachims et al. (2017) 'Unbiased Learning-to-Rank from Biased Feedback', WSDM. DLA as a production-practical alternative to randomisation-based IPW: Ai et al. (2018) 'Unbiased Learning to Rank with Unbiased Propensity Estimation', SIGIR.

## 4.2 New suppliers cannot get started

A new supplier joins and lists products. The model has no data on them, so it assigns them a low score. They get buried on page 2 or 3. Almost no one sees them. Almost no one clicks. The model's view of them never improves. Within 30-45 days, the supplier concludes the platform doesn't work for them and leaves.

The business consequence: we are churning suppliers before we ever give them a fair chance. On this platform, where organic ranking is the only distribution channel, the model is effectively deciding who gets to participate — and it is systematically excluding everyone new.

A rough estimate: a new supplier in a mid-tier query category can expect around Rs.2,700-3,600 in GMV in their first month at cold-start slot positions. That is below any rational threshold for continuing to invest time in listing products.

> **Estimate** Derived from: 500 sessions/day on a mid-tier query (guesstimate), examination probability ~2% at slot 20+ (Joachims et al.), CVR ~3% (Tier 2/3 m-commerce benchmark), AOV Rs.300-400 (public investor disclosures). 
## 4.3 The catalog is shrinking in practice

The two problems above combine into a third: the set of products users actually see is collapsing to a small pool of incumbents. The listed catalog may have thousands of SKUs, but the effective catalog — what gets surfaced — is a small fraction of that.

This matters most for regional and long-tail demand. A buyer in a Tier 3 city searching for something specific is increasingly likely to see results that were not designed for them. They scroll, don't find what they want, and leave. Aggregate conversion looks fine because head queries still perform well. The damage is invisible until it isn't.

The reason this is hard to fix just by fixing the model: even a perfectly debiased model trained on today's data will still rank incumbents higher, because incumbents have years of accumulated (unfairly won) evidence. Reversing concentration requires actively changing what data gets generated — not just how the model is trained.

# 5. Success metrics

The core measurement challenge: the metrics the team watches today — aggregate CTR, model AUC, overall conversion — will all look fine while the loop is running. They are either too aggregated or too lagging to catch it early. We need a different set of metrics, specifically designed to make the loop visible before it becomes structural.

**How to read this section:** leading indicators are what needs to be watched weekly to detect problems early. Lagging indicators are what will be reported to confirm business impact. The trap to avoid: lagging indicators looking healthy while leading indicators are already declining. That gap is exactly how the loop hides.

## 5.1 Leading indicators

These are early warning signals. They should be tracked before any intervention ships, so we have a baseline to measure against.

| **What we're measuring** | **Why it matters** | **Healthy** | **Alarm** |
| --- | --- | --- | --- |
| How evenly impressions are distributed across all listed products (Impression Gini) | If a small number of products are getting almost all the visibility, the catalog is concentrating. Gini of 0 = perfectly even, 1 = one product gets everything. | < 0.75 | > 0.85, or rising 0.02+ in a week |
| How many new suppliers get zero impressions in their first week | A high rate means the model is not giving new sellers any chance to get started. | < 20% of new cohort | > 40% of new cohort |
| How strongly a product's position predicts its click rate (slot-CTR correlation) | Some correlation is expected — better products should rank higher and get more clicks. A very high correlation means position is doing the work, not quality. | Correlation < 0.6 | Correlation > 0.85 |
| How often users search again immediately after a search without buying (query pivot rate) | A user who searches, finds nothing useful, and tries a different search is a user the ranking failed. Especially telling on specific or regional queries. | Within ±10% of baseline | > 15% above baseline on mid-tier queries |
| How often users scroll deeply and leave without clicking (informed abandonment) | Users who scroll past two screens and exit without clicking have looked and decided nothing was relevant. | Within ±10% of baseline | > 20% above baseline |

> **Estimate** Healthy range thresholds are derived from first principles and published benchmarks (Alibaba PAL 2019; Covington et al. 2016 YouTube recommendations), not from platform data. Run 12 weeks of baselines — including at least one major sale period — before treating these numbers as actionable. 

## 5.2 Lagging indicators

These confirm business impact and are what would be reported to confirm business impact. They are slow to move — by the time they show damage, the problem is already advanced. Do not use these as the primary signal for whether the loop is running.

| **Metric** | **What it tells us** | **Why it lags** |
| --- | --- | --- |
| GMV per active user | Are existing users buying more or less over time? Strips out the flattering effect of new-user growth. | New user volume can mask per-user decline for 12-18 months. |
| Conversion rate broken down by category, geography, and query type | Is the drop in tail queries being hidden by strong head query performance? | Aggregate CVR stays healthy long after the tail has collapsed. |
| Supplier 90-day survival rate (by join cohort) | What share of suppliers who joined in a given month are still active 90 days later? | Suppliers take 30-60 days to decide to leave after starvation begins. |
| Return-to-search rate within 14 days of purchase | Are buyers coming back to search for the same thing again shortly after buying? Suggests they bought something that wasn't quite right. | Requires a 14-day observation window per purchase. |

# 6. Requirements

Three workstreams. The sequence is fixed by dependency: we cannot evaluate whether anything is working without measurement infrastructure in place first. Workstreams 2 and 3 run in parallel once Workstream 1 is done.

A note on framing: Workstreams 2 and 3 both have real costs — CVR impact, engineering time, short-term metric degradation. 

## Workstream 1 — Detect (weeks 1-6)

**Goal:** Instrument the leading indicators before touching anything else. Every intervention in Workstreams 2 and 3 needs a before/after baseline to be evaluated.

- The most important first step: Logging which slot each item appeared in at the time it was shown. 
- Build a catalog health dashboard: impression distribution across products (daily), new supplier visibility rate (weekly), position-click correlation (weekly), supplier 90-day survival by cohort (weekly).
- Run these metrics for 12 weeks before setting alarm thresholds. Only four weeks of data will generate false positives from normal seasonal variation.
- Always slice metrics by query tier (head / torso / tail) and geography (metro / Tier 2 / Tier 3). An aggregate metric that looks fine almost certainly has a collapsing tail hiding underneath it.


## Workstream 2 — Stabilise (weeks 4-12)

**Goal:** Slow the damage while the permanent fix is being built. These interventions do not fix the root cause — they buy time and reduce the rate of supplier churn and catalog collapse.

### 2a — Give new items a chance to be seen (exploration budget)

The problem: the model will never voluntarily show new items, because it has no data on them. The solution: reserve a small number of slots per session — 2-3% — specifically for items the model hasn't seen enough of yet. Think of it as a trial shelf: items get a short window of real visibility so we can find out whether users actually want them.

Key decisions and constraints:
- These trial slots must be excluded from the model's training data. If they aren't, the clicks from forced exposure get fed back in as if they were organic — recreating the same bias problem we're trying to fix.
- Place trial items in mid-page positions (slots 4-8), not the top two. Top slots carry too much CVR risk for unproven items.
- This will reduce conversion on those slots by an estimated 5-15%. That cost needs to be explicitly accepted by the business before launch.

> **Validation required** Before setting the threshold for "insufficient data": look at items that eventually became successful sellers and find how many clicks they had before they started converting well. That number sets the threshold.

### 2b — Track which suppliers are being starved (supplier health index)

Rather than exploring randomly across all low-exposure items, we want to direct the exploration budget toward suppliers who are at genuine risk of churning. Build a simple health score per supplier using: how much impression share they are getting relative to peers in their category, how long since their first order, and their quality signals (returns rate, ratings).

Suppliers below a health threshold get automatically included in the exploration pool regardless of their model score. Track the index weekly — two consecutive weeks of decline in new-cohort scores is the trigger for a review.

> **Validation required** Before launching: test the score against historical data on churned suppliers. It should have predicted their churn at least 30 days in advance for at least 70% of cases. If it doesn't, the weights are wrong and needs adjustment.

### 2c — Prevent any one supplier from dominating a results page (diversity constraint)

Cap the number of items from the same supplier that can appear on a single results page. Starting point: no more than 3 items per supplier in fashion categories, 5 in more functional categories.

This is a blunt intervention. It will hurt short-term CTR in cases where one supplier genuinely has the best products. It is a backstop to prevent the worst concentration outcomes while the real fix is being built — not a permanent feature. Once the debiased model is live and the Gini is trending down, this constraint should be relaxed or removed.

> **Validation required** Before setting the cap: check the current average number of items from the same supplier appearing in results for the top 20 queries. If it's already below 3, this constraint will be immediately binding and the CVR cost will be real and visible. If it's 5-8, a cap of 3 buys meaningful diversity without a large hit to conversion.

## Workstream 3 — Fix the root cause (months 2-6)

**Goal:** Retrain the model so it learns actual product relevance, not historical visibility. This is the only intervention that fixes the problem permanently. It will require 3-6 months for the effects to be visible.

### 3a — Logging position data 

Before any debiasing work can begin, we need to know — for every item shown — exactly which slot it appeared in. This needs to be stored and linkable to the click that followed.

### 3b — Decide how we will measure position bias (key decision required)

To correct for position bias in the training data, we need to know how much each slot position inflates click probability. There are two ways to get this:

- **Run a controlled experiment:** Randomly shuffle results for 1-2% of traffic for several weeks. This gives us clean data on how much position affects clicks. It is the more reliable approach — but it means deliberately showing worse results to a small percentage of users. Leadership needs to explicitly approve this.
- **Estimate it from existing data (DLA):** Use a Dual Learning Algorithm (DLA) that infers position bias from existing click patterns, without needing to run an experiment. More practical, but technically more fragile — if set up incorrectly, it produces no debiasing effect at all.

### 3c — Retrain the model with corrected data

Once we have position bias estimates, the ML team reweights the training data so that clicks from high-slot items count for less, and clicks from low-slot items count for more. The model then learns from what users actually wanted and not from what happened to be shown at the top.

How to know if it's working: the gap between the model's accuracy on raw click data vs position-corrected click data should shrink after each retrain.

One important note: this fix does not help items that have near-zero clicks to begin with. The exploration budget from Workstream 2 remains necessary even after this is live. Both are needed and they solve different parts of the problem.

# 7. Risks & assumptions

| **Risk** | **Description** | **Mitigation** |
| --- | --- | --- |
| Exploration budget causes visible CVR drop | 2-3% exploration impressions will convert worse. Without upfront communication, this looks like a regression. | Pre-align with leadership on the cost before launch. Frame it as an investment in catalog health with a defined payback period. |
| DLA converges to a degenerate solution | If poorly initialised, both models can converge to equal examination probabilities for all slots, producing no debiasing. | Use short randomisation experiment data to initialise propensity estimates before switching to DLA. Validate estimates against the known slot-CTR relationship before training. |
| Diversity constraint hurts head-query CVR | For queries where one supplier genuinely dominates on quality, forcing diversity reduces CVR without improving user satisfaction. | Segment constraint by category and query type. Do not apply where concentration is quality-driven (measurable by IPW-corrected relevance score distribution). Apply only where concentration is loop-driven. |
| Logging join non-determinism | If the serving stack re-ranks after logging, or logs asynchronously, stored slot will not match what the user saw. IPW estimates will be wrong. | Audit the serving pipeline before building logging infrastructure. Map every transformation between model score and final render position. |
| Metrics baseline too short | Thresholds set on 4 weeks of data will generate false positives from seasonal variation. | Run baselines for minimum 12 weeks, including at least one major sale period. Alarms should be relative to seasonally-adjusted moving averages, not absolute values. |
| Supplier health index misweighted | Over-weighting impression share will enroll low-quality suppliers in the exploration budget, generating noisy signal and hurting UX. | Validate weights against historical churn data before launch. The index should predict churn 30+ days in advance for at least 70% of churned suppliers in a held-out validation set. |

*Portfolio artefact produced for personal learning. All platform references are anonymised. Assumptions and data gaps are flagged explicitly throughout. Sources are cited where available; estimates show derivation reasoning.*
