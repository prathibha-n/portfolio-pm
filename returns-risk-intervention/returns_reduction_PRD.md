# Product Requirements Document
## Returns Reduction System
### Parts 1 & 2: Risk Scoring Model + Intervention Routing

| Field | Detail |
|---|---|
| Product | Returns Reduction System |
| Scope | Parts 1 & 2 — Risk Scoring + Intervention Routing |
| Last updated | April 2026 |
| Stakeholders | Data Science, Engineering, Ops, Legal/Compliance |

---

## 1. Problem statement

Fashion return rates in India run at 25–40%. Size mismatch is the primary driver — buyers order multiple sizes, keep one, return the rest. The current approach applies blunt policies (blanket COD restrictions, flat return windows) that hurt conversion without meaningfully reducing returns.

The opportunity: return risk is not uniform. It varies significantly by who is buying, what they are buying, and how they are buying it. A system that scores this risk at checkout and applies a proportionate, targeted intervention can reduce returns without degrading conversion.

This PRD covers two Parts that together form the core of this system.

---

## 2. Scope

| In scope | Out of scope |
|---|---|
| Return probability scoring at checkout | Model training infrastructure |
| Feature specification for the scoring model | A/B test framework |
| Intervention decision logic per score band | Post-purchase returns flow changes |
| Per-order decomposition to identify top risk driver | Warehouse or logistics changes |
| Intervention routing based on top driver | Rollout plan |

---

## 3. Part 1 — Return risk scoring model

### 3.1 What this does

At the moment a buyer reaches checkout, the system computes a single probability score between 0 and 1 representing the likelihood that the order will be returned. This score is computed from 11 signals available at checkout time.

A score of 0.75 means the model estimates a 75% chance this specific order will be returned, given the buyer's history, the item they are buying, and the context of this purchase.

### 3.2 Model contract

| Parameter | Specification |
|---|---|
| Output | A single probability score between 0 and 1 per order |
| Label (training) | Binary — did this order get returned within 30 days? |
| Inference timing | At checkout, before payment confirmation |
| Latency requirement | Response within 100ms — must not slow checkout |
| Retraining cadence | Weekly, on the last 90 days of orders |
| Cold-start handling | First-time buyers: score falls back to category base rate only |

### 3.3 The 11 input signals

| Feature | Type | Source | Group | Why it matters |
|---|---|---|---|---|
| user_return_rate_90d | 0–1 | Orders DB | User history | Recency-weighted behaviour. Strongest individual signal. |
| user_return_rate_1yr | 0–1 | Orders DB | User history | Long-run baseline. Corrects for seasonal noise in 90d window. |
| user_order_count | Integer | Orders DB | User history | Cold-start correction. Low count = low confidence in rate estimates. |
| category_base_rate | 0–1 | Catalogue DB | Item | Structural prior. Swimwear ~35%, accessories ~8%. |
| size_selection_confidence | 0–1 | Size tool events | Item | Did user consult and follow size guide? Low = uncertain = higher risk. |
| size_changed_in_session | Yes / No | Session events | Item | Swapped size in cart. Each swap signals indecision. |
| price_band | Low/Mid/High | Catalogue DB | Item | High-price orders tend to be deliberate. Low-price = impulse. |
| payment_method_cod | Yes / No | Payments DB | Context | COD buyers have no financial commitment at order time. |
| device_type | App/Web | Session events | Context | App users show higher purchase intent than mobile web. |
| is_first_order | Yes / No | Orders DB | Context | No history available. Score falls back to category base rate. |
| images_viewed_count | Integer | Session events | Context | More images viewed = more deliberate purchase decision. |

### 3.4 Features explicitly excluded

| Excluded feature | Reason |
|---|---|
| Delivery pincode / area | High return rates in tier-2/3 cities reflect infrastructure gaps, not buyer intent. Using pincode penalises legitimate buyers in underserved markets — a geographic discrimination proxy. |
| Device price proxy | Inferring income from device model is an income-discrimination proxy. Device type (app vs web) is used instead — it tracks intent, not wealth. |
| New account age flag | Penalising new accounts harms the highest-LTV acquisition target. First-order flag is used only to switch scoring logic, not as a risk multiplier. |
| Return reason text | Return reason is recorded after the event — it is unavailable at checkout. Including it in training would cause data leakage. Excluded from v1. |

### 3.5 Assumptions & guesstimates — Part 1

> **Note:** All items below are assumptions or estimates. 

- Fashion return rates in India run 25–40%. Source: RedSeer 2023 E-commerce report. 
- COD orders return at approximately 2x the rate of prepaid orders. Source: RedSeer 2023. 
- Each size change in a session adds approximately 3 percentage points to return probability. This is a directional estimate. Actual coefficient will be learned from data.
- The 30-day return window as the label definition assumes most returns happen within 30 days. 
- A minimum of 50,000 historical return events is assumed to be available for training. Below this threshold, model reliability degrades.
- `size_selection_confidence` is assumed to be a computable signal from existing size tool events. If the size tool does not log recommendation vs selection, this feature is unavailable and must dropped.
- The 90-day and 1-year return rate windows are chosen based on general e-commerce patterns. 
---

## 4. Part 2 — Intervention routing

### 4.1 What this does

Once a score is computed, the system decides whether to intervene and — if yes — what to show the buyer. The core insight is that the same score can arise from very different causes, and the right intervention depends on the cause, not just the score.

Example: two orders both score 0.72.
- Order A: high COD usage + high return history. Right intervention: prepaid incentive.
- Order B: very low size confidence + size switch in session. Right intervention: size guide gate.

Showing a size guide to Order A or a COD restriction to Order B would be the wrong call. The routing logic prevents this.

### 4.2 Two-axis decision logic

Every intervention decision uses two axes together:

- **Score band** — sets the severity of intervention (how hard do we push?).
- **Top driver** — sets the type of intervention (what do we say?).

Score band alone is insufficient because it ignores cause. Top driver alone is insufficient because a low-confidence size selection on a 0.35-score order does not warrant friction. Both are required.

### 4.3 Score band definitions

| Score band | Severity | What fires | Notes |
|---|---|---|---|
| Below 0.40 | None | No intervention. Checkout proceeds normally. | ~60–65% of orders. Target. |
| 0.40 – 0.70 | Soft | Nudge only. Type determined by top driver. | Size guide, exchange offer, category tip. |
| 0.70 – 0.85 | Medium | Nudge by top driver + COD friction if COD is in top 3 drivers. | Prepaid incentive shown alongside nudge. |
| Above 0.85 | Hard | COD restricted regardless of top driver. Alternative always shown. | Never silently block. Always show reason + alternative. |

The hard band (above 0.85) is the only band where intervention type is fixed regardless of top driver. COD restriction at this threshold is justified by the high confidence in the prediction. The ethical requirement — always showing a reason and an alternative — is non-negotiable and must be enforced at the product layer, not left to copy.

### 4.4 Intervention table

| Top driver | Intervention type | Message shown to user |
|---|---|---|
| payment_method_cod | Prepaid incentive | *Pay now and get free size exchange + 10% credit on your next order.* |
| size_selection_confidence | Size guide gate | *You skipped the size guide. 3 in 10 customers return this category — it takes 30 seconds.* |
| size_changed_in_session | Size confirmation nudge | *You changed your size. Want to re-check with the size guide before confirming?* |
| user_return_rate_90d | Exchange-first offer | *If this doesn't fit, exchange for the right size — free pickup, no questions asked.* |
| user_return_rate_1yr | Exchange-first offer | *If this doesn't fit, exchange for the right size — free pickup, no questions asked.* |
| category_base_rate | Category size tip | *Sizing in this category runs small. Most buyers go one size up.* |
| is_first_order | Size guide gate | *First order? Our size guide takes 30 seconds and halves the chance you will need to return.* |
| images_viewed_count | Product detail nudge | *You have not seen all product images. Check the size chart photo before confirming.* |
| device_type | No intervention | Weak standalone signal. No user-facing action. |
| user_order_count | No intervention | Cold-start signal used for scoring only. No user-facing action. |
| price_band | No intervention | Used as a severity modifier only. No standalone user message. |

If the top driver maps to `no_intervention`, the routing logic automatically falls back to the feature with the next highest contribution that has a defined intervention.

### 4.5 Ethical guardrails

- COD is never silently blocked. The buyer always sees the reason and an alternative path to complete the purchase.
- No intervention is applied on the basis of pincode, device price, or any income proxy.
- Interventions in the soft and medium bands are nudges, not gates. The buyer can always proceed without engaging with the nudge.
- The hard band (COD restriction) is a gate. It needs to be reviewed by legal and compliance. If this breaches consumer rights, Hard nudges will be dropped.

### 4.6 Known tradeoff — precision vs recall

There is an inherent tradeoff between precision and recall that this system does not fully resolve and is not expected to resolve at v1.

Higher recall (catching more real returners) comes at the cost of lower precision (more false positives — legitimate buyers who get flagged). For soft interventions such as size guide nudges, this tradeoff is acceptable: the cost of showing a nudge to a low-risk buyer is low. For hard interventions such as COD restriction, lower precision is more costly — legitimate buyers are blocked.

The score band design partially addresses this by reserving hard interventions for the highest score band (above 0.85), where precision is highest. The tradeoff at the soft and medium bands is acknowledged and accepted for v1.

### 4.7 Success metrics

| Metric | Type | Target | Notes |
|---|---|---|---|
| Return rate | Primary | Reduce by 15–20% | Measured on intervention cohort vs control. |
| COD order share | Primary | Reduce by 5–8pp | Shift to prepaid via incentives, not hard blocks. |
| Conversion rate | Guardrail | Degrade less than 1% | Monitored per intervention type separately. |
| NPS / complaint rate | Guardrail | No significant increase | Especially for hard band (COD restriction). |
| Exchange rate | Secondary | Increase 10–15% | Exchanges preferred over full returns. |

Conversion rate is a guardrail, not a target. If conversion degrades beyond 1% on any intervention type during rollout, that intervention is paused pending investigation.

### 4.8 Assumptions & guesstimates — Part 2

> **Note:** All items below are assumptions or estimates. 

- The 10–20% intervention rate target is based on the principle that interventions touching more than 20% of orders will meaningfully degrade conversion. 
- The 0.40 threshold for intervention is a starting point. Optimal threshold should be calibrated against real data to hit the 10–20% intervention rate target.
- The 0.85 threshold for COD restriction is conservative by design. A false positive (legitimate buyer blocked from COD) generates complaints and potential chargeback risk. 
- The prepaid incentive (free size exchange + 10% credit) is assumed to be commercially viable. Finance sign-off required.
- Exchange-first offer is assumed to reduce the proportion of full returns. If the exchange fulfilment cost exceeds the full return cost in certain categories, the intervention table must be updated for those categories.
- The fallback logic (walk to second-highest driver if top driver has no intervention) assumes the second driver is a meaningful signal. If the top two drivers both map to `no_intervention`, the system fires no action — this is an edge case.
---

