### Citibike Dataset - Identification of Casual Riders through ride data only

Predict whether a Citi Bike trip belongs to a Member or Casual rider, using ride behavior alone - with the business goal of identifying casual riders whose behavior already resembles a member's, as targets for conversion.

### Problem
Predict whether a Citi Bike trip belongs to a Member or Casual rider, using ride behavior alone (no demographic data available) — with the business goal of identifying casual riders whose behavior already resembles a member's, as targets for conversion.

### Key EDA findings
Six behavioral signals were tested; all pointed in the same direction — casual riders behave more like leisure/tourist users, members behave like commuters:

| Feature | Direction | Signal Strength |
|---|---|---|
| Trip duration | Casual > Member | Strong |
| Trip distance | Casual > Member | Moderate |
| Rideable type (e-bike %) | Casual > Member | Moderate |
| Hour-of-day shape | Casual flatter, Member two-peaked (commute) | Strong |
| Day-of-week (weekend share) | Casual > Member | Moderate |
| Same-station (loop trips) | Casual > Member | Weak but consistent |

### Modeling results

| Model / Change | Best Casual F1 |
|---|---|
| Logistic Regression (baseline) | 0.21 |
| Random Forest (untuned) | 0.21 |
| Random Forest (tuned depth) | 0.24 |
| XGBoost (default) | 0.23 |
| Random Forest (tuned + speed feature) | **0.25** |

### What this means
- The dataset has an inherent ~91/9 class imbalance (member/casual), which makes accuracy a misleading metric throughout — a model that always predicts "member" scores ~91% accuracy while being useless. Precision, recall, and F1 for the casual class were used instead.
- Three genuinely different model types (linear, bagged trees, boosted trees), hyperparameter tuning, a full decision-threshold sweep, and an additional engineered feature (speed = distance/duration) were all tested. F1 for the casual class moved only from 0.21 to 0.25 across all of this — a real but modest gain, with diminishing returns on each additional change.
- This convergence across different techniques is evidence that the ceiling here is largely in the **available features**, not in model choice or tuning. The six behavioral features used capture a real but limited amount of the difference between member and casual riders.

### Business takeaway
A model at this performance level (~30% recall, ~22% precision at the best operating threshold) is weak on its own but not useless — it could reasonably support a **low-cost, low-risk intervention** (e.g., an in-app nudge or email) where being wrong most of the time is an acceptable cost, but should not be used to justify an expensive or high-friction conversion campaign.

### What could improve this further (not tested here)
- Station-level features (commuter-hub vs. leisure-hub classification) — scoped out for time
- A joined external dataset (e.g., weather) for richer context
- More exhaustive hyperparameter search (grid/random search rather than manual tuning)
