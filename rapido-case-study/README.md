# Rapido Case Study: My Route Booking — How a Simple Allocation Weight Change Doubled Driver Pings

> **Role:** Product Manager, Supply & Marketplace  
> **Feature:** My Route Booking (preferred destination for drivers)  
> **Experiment:** A/B test across Delhi and Jaipur  
> **Core result:** Drivers who set a destination through My Route Booking got pinged 2× more and accepted rides 90% of the time (up from ~80%)

---

## The Problem

Driver utilization in Rapido's markets wasn't just a supply problem — it looked like one on the surface, but the data told a more specific story.

Drivers were online. Demand existed. But idle time was high and acceptance rates were inconsistent, especially during three windows: the morning start-of-shift, the afternoon lull, and the evening end-of-shift run home.

The instinct in most marketplace teams would be to reach for incentives — surge multipliers, guaranteed earnings, bonus structures. We considered it. But before going there, I wanted to understand *why* drivers were sitting idle when rides were available to accept.

---

## The Diagnosis

I spent time talking to drivers in Delhi and Jaipur — not through a formal research program, but directly, with city ops teams who had the relationships. The pattern that came back was consistent:

Drivers weren't passive supply waiting for any ping. They had a destination in mind.

A driver finishing a shift in South Delhi didn't want a ride to Gurgaon. A driver starting his day in Jaipur's old city wanted to work his way toward the newer commercial zones, not take a ride that pulled him deeper into the old city's narrow lanes. An afternoon driver killing time near a transit hub wanted rides that moved him toward his family's neighborhood before school pickup.

When a ping came in that conflicted with where they wanted to go, they'd either reject it or — more often — just sit and wait for one that fit. That selective waiting *was* the idle time problem.

This wasn't drivers gaming the system. It was rational behavior: fuel costs money, time costs money, and an accepted ride in the wrong direction compounds both problems.

**The root cause wasn't supply shortage or low incentives. It was a mismatch between how the allocation system thought about drivers (as interchangeable, proximity-ranked supply) and how drivers actually made decisions (as agents with destinations and shift logic).**

---

## The Hypothesis

> If we let drivers declare a preferred destination and increase their attractiveness weight in the allocation model for rides along that route, drivers who engage with the feature will accept more rides, sit idle less, and be easier to match — because we're finally offering them rides they actually want.

The secondary hypothesis: this would create a flywheel. Drivers who feel the product works for them stay online longer and return more consistently.

---

## What We Built: My Route Booking

The solution was deceptively simple. Drivers could set a destination they wanted to reach — home, a preferred zone, wherever — and the allocation engine would increase their attractiveness score for rides that moved them in that direction.

No new matching infrastructure. No overhaul of the dispatch system. **Just a weight adjustment in how the marketplace ranked driver candidates for a given ride request.**

From a product standpoint, the driver-facing piece was a simple destination-setter in the app. From an engineering standpoint, the core change was:

- Drivers with an active preferred destination get a higher attractiveness weight in candidate ranking for rides that directionally align with their route
- The weight increase is proportional to alignment — a ride going exactly toward the destination scores higher than one that's only partially aligned
- Drivers without a set destination are unaffected; the baseline allocation logic runs as normal

The insight was that we didn't need to *restrict* allocation. We just needed to *surface* these drivers more prominently for the right rides. The marketplace would do the rest.

---

## Experiment Design

We ran an A/B test across Delhi and Jaipur — two cities with meaningfully different demand patterns (Delhi: high density, complex zones; Jaipur: more dispersed, shift-driven supply) — which gave us a useful robustness check.

**Control:** Standard allocation, no destination feature available  
**Treatment:** My Route Booking enabled; drivers who set a destination receive the increased attractiveness weight

**Primary metrics:**
- Ping rate (rides offered per hour online) for drivers who set a destination
- Acceptance rate for treatment drivers
- Idle time between rides

**Guardrail metrics:**
- Customer ETA (confirm that preferencing certain drivers didn't hurt rider experience)
- Ping rate for drivers who *didn't* use the feature (we didn't want to cannibalize their volume)

*Note on numbers: Specific idle time figures and statistical confidence intervals are illustrative in the SQL file. The ping rate (2×) and acceptance rate (80% → 90%) are real outcomes from the experiment.*

---

## Results

The results were cleaner than almost anything I'd seen in a marketplace experiment.

**Drivers who turned on My Route Booking and set a destination:**
- Got pinged **2× as often** as they had been before
- Accepted rides **90% of the time** (up from ~80% baseline)

The mechanism was working exactly as hypothesized: by surfacing these drivers for rides that aligned with where they wanted to go, we eliminated the friction that made them selective. They didn't need to evaluate each ping carefully — the ride was already going their direction.

The signal held across both cities. Delhi and Jaipur have very different market structures — Delhi's density means more ride options per driver, Jaipur's more dispersed supply means longer waits between pings. The fact that the effect was consistent across both made the result more convincing, not less.

---

## Why This Worked (And What It Taught Me)

**1. The solution matched the actual mental model of the user.**  
Drivers don't think of themselves as supply nodes. They think of themselves as people trying to make money efficiently on the way to somewhere. The feature worked because it finally let the product reflect that. Most supply-side interventions treat drivers as passive — this one treated them as agents.

**2. A weight change is not a "small" change in a marketplace.**  
The engineering footprint was minimal. But changing who gets surfaced for which rides restructures the entire matching dynamic. I had to be careful about guardrail metrics for exactly this reason — a naive weight increase could have cannibalized pings for drivers who didn't use the feature. It didn't, but we watched for it.

**3. Behavioral idle time is invisible in aggregate metrics.**  
The problem showed up as "high idle time" at the city level. Nothing in the dashboard pointed to preferred-route behavior as a cause — that only came from talking to drivers. Quantitative data told us *where* the problem was. Qualitative research told us *why*.

**4. The simplest hypothesis is often the right one.**  
My first instinct was to model a more complex allocation rewrite — state signals, heading vectors, recent behavior weighting. The actual fix was: ask drivers where they want to go and offer them relevant rides. Sometimes the product problem is that you haven't asked the user a basic question.

---

## What I'd Explore Next

- **Proactive destination prompts at shift boundaries.** Drivers use this heavily at start and end of shift. Can we prompt destination-setting at these times rather than waiting for drivers to initiate?
- **Tier-3 city rollout.** Delhi and Jaipur were a useful pair. A smaller market would tell us how route density interacts with the feature's effectiveness.
- **The non-user gap.** Drivers who didn't engage with the feature didn't see a degradation in pings — but did they miss the improvement? There's a question about whether the feature should be more prominent or default-on in some form.

---

## Appendix: Files in This Repository

| File | Description |
|---|---|
| `README.md` | This document |
| `allocation-flow.png` | Before/after allocation flow — standard proximity ranking vs. destination-weighted attractiveness |
| `experiment-analysis.sql` | SQL for measuring the experiment: ping rate and acceptance rate by variant, city, and driver cohort |
