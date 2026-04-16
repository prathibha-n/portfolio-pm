# Returns Risk Intervention System
### A checkout-time return prediction and intervention routing system for fashion e-commerce

---

## The problem

Fashion return rates in India run at 25–40%. Size mismatch is the primary driver. The default response — blanket COD restrictions, flat return windows — hurts conversion without meaningfully reducing returns.

The insight: return risk is not uniform. Two orders can look identical on the surface but have completely different risk profiles depending on who is buying, what they are buying, and how they are buying it. A system that scores this risk at checkout and applies a targeted intervention based on the *cause* of that risk can reduce returns without degrading conversion.

---

## What this repo contains

| File | What it is |
|---|---|
|'returns_reduction_PRD.md`| The core documentation. Contains detailed business logic, feature specifications, and ethical guardrails.|
| `return_risk_model.ipynb` | End-to-end Python notebook: feature spec → model → scoring → decomposition → intervention routing |
| `flowchart.drawio.png` | Algorithmic flowchart of the intervention routing decision logic |
| `readme.md` | This file |

---

## How the system works — the short version

**Step 1 — Score**
At checkout, 11 signals are collected for every order: user return history, category base return rate, size selection confidence, payment method, price band, device type, and others. These are fed into a model that outputs a single number — p(return) — the probability that this order will be returned.

**Step 2 — Decompose**
If the score crosses a threshold (default 0.50), the score is decomposed into per-feature contributions. This identifies the *top driver* — the single feature most responsible for the high score.

**Step 3 — Route**
The routing function uses two axes together to decide what to show the buyer:
- **Score band** — sets severity (how hard do we push?)
- **Top driver** — sets message type (what do we say?)


The key design principle: **the same score via different causes gets a different intervention.** A 0.73 score driven by low size confidence gets a size guide gate. A 0.73 score driven by COD gets a prepaid incentive. Showing the wrong intervention for the cause would be both ineffective and bad UX.

---

## How to read this repo

**If you want to understand the logic, start with the flowchart.**
`flowchart.drawio.png` shows the full decision algorithm top to bottom — score thresholds, decomposition, driver lookup, and intervention output. Read this before the code.

**If you want to run or extend the model, open the notebook.**
`return_risk_model.ipynb` is structured sequentially. Each section builds on the previous one:

1. **Feature registry** — the 11 input signals, their sources, and why each is included
2. **Synthetic data** — stand-in for a real orders table; replace with a SQL query against your orders DB
3. **Model training** — logistic regression with class weight balancing; outputs p(return)
4. **Coefficient table** — global feature importance; use this to validate the model is learning sensible weights
5. **Score a single order** — the function that runs at checkout
6. **Decomposition** — pulls apart the score into per-feature contributions; identifies top driver
7. **Intervention table** — one intervention type mapped to each feature
8. **Routing function** — combines score band and top driver into a single intervention decision
9. **Batch scoring** — distribution check; tune threshold until 10–20% of orders fall into intervention bands

**If you want to use this on real data**, the only change needed is in section 2 of the notebook — replace the synthetic data generator with a query to your orders table. Everything downstream is the same.

---

## Limitations

- Model is trained on synthetic data. AUC and classification metrics will change on real data.
- There is an inherent tradeoff between precision and recall. Higher recall (catching more real returners) comes at the cost of more false positives. For soft interventions this is acceptable. For hard interventions (COD restriction), the threshold is deliberately conservative.
- The routing logic handles the top driver only. Orders where the top two drivers both map to no intervention (~2% estimated) receive no action.

---

## Stack

- Python 3.10+
- scikit-learn — logistic regression, scaling, evaluation
- pandas, numpy — data handling
- No external ML infrastructure required for v1
```
