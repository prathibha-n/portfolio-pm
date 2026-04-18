# Ranking feedback loop collapse

I picked this problem because it is one of the most silent failure modes in marketplace ranking — dangerous specifically because every standard metric looks healthy while the damage compounds underneath.

This project works through the full problem: understanding why the loop forms, simulating how it compounds over time, and building the case for how to fix it. The accompanying PRD (`ranking_feedback_loop_PRD.md`) is the PM artefact that comes out of that process.

---

## The problem in one paragraph

A ranking model trained on clicks will, over time, learn to predict which items have historically been shown at the top — not which items are actually relevant. Items shown in high slots get more clicks simply because users see them first. The model reads this as a quality signal and ranks those items higher next cycle. New and niche suppliers, who never get enough visibility to accumulate clicks, churn before the model ever learns whether their products were good. The catalog concentrates. Regional and long-tail demand goes unserved. And the whole time, aggregate metrics — CTR, conversion, model AUC — report green.

---

## How to explore this project

The files are sequenced to build understanding progressively. If you are a PM without a data background, the notebooks are worth opening — they are visual and the key insight in each is accessible without needing to read the code.

### Start here: understand the mechanism

**`01_feedback_loop_formation.ipynb`** — simulates how the loop forms from scratch. Shows what happens to impression share and supplier visibility across retraining cycles when click data is used as-is. The Gini coefficient rising across cycles is the key output to look at.

### Then: understand what the fix looks like

**`02_ipw_correction.ipynb`** — simulates the Inverse Propensity Weighting (IPW) correction. IPW reweights each click by how likely the user was to have seen the item at all — so clicks from top slots count for less, and clicks from buried slots count for more. The model then learns relevance, not visibility. The notebook shows the difference in item score distributions before and after correction.

The `.png` files are visual outputs from each notebook — charts and summaries of the key conclusions at each stage of the analysis. They are useful if you want a quick read of what each notebook produces without running the code.

### Finally: the PM artefact

**`ranking_feedback_loop_PRD.md`** — the full PRD. Covers platform context, persona analysis, problem decomposition, success metrics, and a three-workstream requirements plan (detect → stabilise → fix). Written from a PM's perspective: what decisions need to be made, what the team is being asked to build, and what leadership needs to explicitly sign off on.

---

## What this project is not

The simulations use synthetic data and simplified assumptions. They are not a production model — they exist to make the mechanism visible and testable. All assumptions are flagged in the PRD and the notebooks. The point is to demonstrate the reasoning process, not to produce production-ready code.

---

## Platform context

This project is scoped to a zero-commission reseller marketplace targeting Tier 2 and Tier 3 cities in India, with micro-entrepreneur suppliers and no advertising product. This platform model was chosen deliberately — organic ranking is the only distribution channel available to suppliers, which makes the feedback loop's damage faster and harder to reverse than on platforms where suppliers can pay for initial visibility.
