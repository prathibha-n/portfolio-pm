# PRD: AI Voice Assistant for Delivery Drivers
**Product:** Voice AI for Last-Mile Delivery Drivers
**Author:** [PM — New Initiatives, Last-Mile Delivery Platform]
**Status:** Draft v1.0
**Last Updated:** April 2026
**Review cycle:** 2 weeks
**Stakeholders:** Last-Mile Ops, Driver Experience, Data Science, City Ops, Safety & Compliance

---

## Table of Contents

- [A note on data sourcing](#a-note-on-data-sourcing)
- [1. Problem Statement](#1-problem-statement)
  - [1.1 The Core Tension](#11-the-core-tension)
  - [1.2 What the Evidence Shows](#12-what-the-evidence-shows)
  - [1.3 Why Now](#13-why-now)
- [2. Goals & Non-Goals](#2-goals--non-goals)
  - [2.1 Goals](#21-goals)
  - [2.2 Non-Goals (v1)](#22-non-goals-v1)
- [3. User Personas](#3-user-personas)
- [4. User Stories](#4-user-stories)
  - [4.1 Core Navigation & Order Flow](#41-core-navigation--order-flow)
  - [4.2 Issue Reporting & Escalation](#42-issue-reporting--escalation)
  - [4.3 Earnings & Shift Management](#43-earnings--shift-management)
- [5. Feature Specification](#5-feature-specification)
  - [5.1 Activation](#51-activation)
  - [5.2 Command Taxonomy](#52-command-taxonomy)
  - [5.3 Dialogue Design Principles](#53-dialogue-design-principles)
  - [5.4 AI Model Architecture](#54-ai-model-architecture-high-level)
- [6. Success Metrics](#6-success-metrics)
  - [6.1 North Star Metric](#61-north-star-metric)
  - [6.2 Primary Metrics](#62-primary-metrics)
  - [6.3 Secondary Metrics](#63-secondary-metrics)
  - [6.4 Guardrail Metrics](#64-guardrail-metrics-must-not-regress)
- [7. Launch Plan](#7-launch-plan)
  - [Phase 0: Research & Instrumentation](#phase-0-research--instrumentation-weeks-14)
  - [Phase 1: Dark Store Pilot](#phase-1-dark-store-pilot-weeks-510)
  - [Phase 2: City Pilot](#phase-2-city-pilot-weeks-1120)
  - [Phase 3: Multi-City Rollout](#phase-3-multi-city-rollout-weeks-2136)
  - [Phase 4: National Default](#phase-4-national-default-week-37)
- [8. Risks & Mitigations](#8-risks--mitigations)
- [9. Open Questions](#9-open-questions)
- [10. Appendix](#10-appendix)
  - [A. Research Plan Summary](#a-research-plan-summary)
  - [B. Technical Dependencies](#b-technical-dependencies)
  - [C. Unit Economics Estimate](#c-unit-economics-estimate--driver-replacement-cost)
  - [D. Glossary](#d-glossary)

---

## A note on data sourcing

Every quantitative claim in this PRD is tagged with a source type. No number should be taken as ground truth without validating it against your platform's own instrumentation.

| Tag | Meaning |
|---|---|
| `[HYPO]` | Hypothesis — not yet observed; basis and how-to-validate described inline |
| `[OBS]` | Direct observational research — ride-alongs, field shadowing, screen recordings |
| `[INT]` | Driver interviews or focus groups |
| `[LOG]` | Product analytics / server-side log data |
| `[LIT]` | Published third-party research, cited inline |
| `[IND]` | Industry benchmark from public report, cited inline |
| `[EST]` | Structured estimate — method described inline |

---

## 1. Problem Statement

### 1.1 The Core Tension

Last-mile delivery platforms make a time-based promise — typically 30–45 minutes — that rests almost entirely on the driver. Every order requires a driver to:

- Navigate unfamiliar or ambiguous addresses in dense urban environments
- Communicate with merchants, customers, and support in real time
- Tap through multiple app screens per order, often one-handed, while stationary in traffic or between legs of a ride

The delivery driver app was designed for a smartphone user at rest. Drivers use it under conditions of extreme cognitive and physical load: one hand on a handlebar, ambient noise from traffic, time pressure, often operating in a second language. **The interface is mismatched to the context in which it is used.**

### 1.2 What the Evidence Shows

> **Honesty note:** No primary research has been conducted for this document. The figures below are working hypotheses — either structured estimates based on how these systems typically work, or industry benchmarks from published sources. Each entry states its basis clearly and describes exactly how to replace the hypothesis with a real number.

---

**Taps per order: estimated 8–11** `[HYPO]`

*Basis:* Derived by manually counting the discrete tap interactions required to complete a full order lifecycle in a typical delivery driver app (accept order, open maps, mark arrived at merchant, mark picked up, open maps again, mark arrived at drop, confirm OTP, mark delivered). The lower bound assumes a practised driver with muscle memory; the upper bound assumes a new driver who hesitates, re-reads, or makes an error and backtracks. This has not been observed on any specific platform.

*How to validate:* Instrument the driver app to log `touchstart` events with a screen identifier. Run for 2 weeks across a sample of 200+ drivers stratified by tenure. Calculate median and P90 taps per completed order. Segment by new vs. experienced driver to confirm the spread.

---

**% orders involving at least one inbound driver support call: guesstimate ~10–15%** `[EST]`

*Basis:* This is a guesstimate derived from logical assumptions, not observed or published data. The reasoning: a delivery order has three structurally failure-prone handoff points — merchant readiness, address resolution, and customer contact at drop. If each has a ~4–6% independent failure rate (a conservative assumption for an urban, time-pressured context), the cumulative probability of at least one requiring a support call lands in the 10–15% range. The driver-initiated share is assumed to be roughly half of total platform support volume, consistent with the general pattern that customers and drivers generate roughly equal contact load on delivery platforms.

*How to validate:* Pull CRM data for inbound support contacts. Tag by initiator (driver vs. customer) and by order state at time of contact (active delivery, pre-pickup, post-delivery). Formula: driver-initiated contacts during active delivery ÷ total orders in the same window. Any platform with a CRM and dispatch system can produce this in a single query. Methodology reference: [digitalgenius.com/blog/contact-to-order-ratio](https://www.digitalgenius.com/blog/contact-to-order-ratio).

---

**Top support call reasons: navigation confusion, OTP/handoff issues, order not ready at merchant** `[HYPO]`

*Basis:* Reasoned hypothesis from first principles. These three categories represent the most structurally likely failure points in a delivery flow: (1) address resolution fails at the navigation step; (2) OTP handoff is a synchronisation problem between two parties under time pressure; (3) merchant readiness is outside the driver's control.

*How to validate:* Two approaches, ideally run in parallel. First, pull existing support ticket data and apply a category taxonomy — most CRM systems allow tagging by contact reason; if not, sample 200 tickets and manually code them. Second, run 15–20 critical incident interviews with drivers using the prompt: *"Tell me about the last time you had to call support during a delivery. Walk me through what happened."* Open-code responses. Cross-check the two datasets. Expect the ticket data and interview data to diverge — the interview data will surface reasons drivers don't call support even when they should.

---

**Average support handle time: ~4 minutes** `[EST]`

*Basis:* Could not find sources to Literature. The 3–5 minute handle time range is consistent with general customer service benchmarks for app-based platforms. McKinsey publishes broadly on gig operations at [mckinsey.com/featured-insights/future-of-work](https://www.mckinsey.com/featured-insights/future-of-work) but does not publish a specific handle time benchmark for gig delivery driver support. Handle time is highly variable by contact reason — a navigation query resolved by an agent reading an address aloud takes ~2 minutes; an order dispute requiring evidence review takes 8+ minutes.

*How to validate:* Pull average handle time from the CRM, filtered to driver-initiated contacts during active deliveries. Segment by contact reason category once that taxonomy is established (see above). The aggregate figure is less useful than the per-reason breakdown for sizing the opportunity.

---

**Driver NPS: estimated 28–35 for delivery platforms in growth markets** `[EST]`

*Basis:* Could not find sources to Literature. The 28–35 NPS range for gig delivery worker satisfaction in growth markets is plausible based on general gig worker sentiment research, but should be treated as an unverified planning assumption. Bain's NPS research hub ([bain.com/insights/topics/loyalty](https://www.bain.com/insights/topics/loyalty/)) and BCG's gig economy work ([bcg.com/capabilities/people-strategy/future-of-work](https://www.bcg.com/capabilities/people-strategy/future-of-work)) are the closest relevant bodies of research, but neither publishes a specific NPS benchmark for gig delivery drivers in growth markets. 

*How to validate:* Run a driver NPS pulse survey. A single-question survey ("How likely are you to recommend driving for this platform to a friend or colleague?") deployed via in-app notification after shift completion, with a 10% random sample, will produce a statistically reliable NPS in 2–4 weeks depending on fleet size. Segment results by tenure tier and city to identify where dissatisfaction is concentrated.

---

**Near-miss incidents involving device interaction while in motion: ~20–25% directional estimate** `[LIT]`

*Basis:* Two published bodies of research are directionally relevant. MoRTH (India) publishes annual road accident data at [data.gov.in](https://data.gov.in) and the Road Accidents in India report series at [morth.nic.in](https://morth.nic.in) — this data consistently shows two-wheelers as the highest-risk vehicle category in urban India, with handheld device distraction as a contributing factor, though a specific causation percentage is not published in a standalone findable document. Monash University Accident Research Centre (MUARC) publishes delivery rider safety research at [monash.edu/muarc](https://www.monash.edu/muarc) — peer-reviewed research on platform delivery rider safety (e.g., Wang & Churchill, *Journal of Sociology,* 2025, [doi.org/10.1177/14407833241246571](https://journals.sagepub.com/doi/10.1177/14407833241246571)) confirms that phone interaction during riding is a documented safety risk. The ~20–25% estimate is a planning assumption derived from the directional weight of this research.

*How to validate:* Platform-level safety data is difficult to collect directly. Two proxies are feasible: (1) add a post-incident report question to the existing driver app incident reporting flow — "Were you interacting with your phone immediately before the incident?" — and track the response rate over 6 months; (2) instrument the app to flag sessions where a tap interaction occurs while GPS velocity exceeds a walking-speed threshold (e.g. >15 km/h), then correlate those sessions with subsequent incident reports.

---

**Driver monthly churn: estimated 25–30%** `[EST]`

*Basis:* Could not find sources to Literature. The 25–30% monthly churn range is corroborated directionally by: (1) public reports of Amazon DSP driver churn of ~50% in the first 90 days ([spoke.com/dispatch/blog/last-mile-delivery-challenges](https://spoke.com/dispatch/blog/last-mile-delivery-challenges)); (2) Scandit's delivery driver workforce survey finding 40% of experienced contractors leave within a year ([scandit.com/blog/key-to-last-mile-success](https://www.scandit.com/blog/key-to-last-mile-success/)). Kearney publishes last-mile logistics research at [kearney.com/industry/consumer-retail-and-fast-moving-consumer-goods](https://www.kearney.com/industry/consumer-retail-and-fast-moving-consumer-goods) but no specific churn benchmark has been found publicly. 

*How to validate:* Churn is directly calculable from dispatch data. Formula: drivers who completed at least one order in month M but zero orders in month M+1 ÷ active drivers in month M. Run this for the past 12 months and segment by city age, driver tenure cohort, and weekly earnings bracket. The earnings bracket segmentation typically reveals the most actionable insight — high churn is usually concentrated in drivers earning below a threshold that makes the work economically viable.

---

| Signal | Estimate | Status |
|---|---|---|
| Avg. screen taps per order | 8–11 | `[HYPO]` — needs app instrumentation |
| % orders with ≥1 driver support call | ~10–15% guesstimate | `[EST]` — logical assumption, needs CRM validation |
| Top 3 call reasons | Navigation, OTP, merchant delay | `[HYPO]` — needs ticket analysis + interviews |
| Avg. support handle time | ~4 min | `[EST]` — no published benchmark found; needs CRM |
| Driver NPS | 28–35 | `[EST]` — no published benchmark found; needs pulse survey |
| Near-miss incidents during device use | ~20–25% directional | `[LIT]` — directional only; no citable specific figure |
| Monthly driver churn | 25–30% | `[EST]` — no published benchmark found; needs dispatch data |

### 1.3 Why Now

**1. NLP maturity for regional languages.** Word Error Rate (WER) for South Asian and Southeast Asian languages has fallen below 8% in ambient noise equivalent to urban traffic (70–80 dB) — *Google Cloud Speech-to-Text benchmark, Q3 2024 ([cloud.google.com/speech-to-text](https://cloud.google.com/speech-to-text)); Sarvam AI technical whitepaper, 2024 ([sarvam.ai](https://www.sarvam.ai)).* This was not achievable at production scale 24 months ago.

**2. A regulatory forcing function is building.** Road safety regulators across multiple markets have signalled intent to mandate hands-free device use for commercial two-wheeler operators. MoRTH publishes annual road accident data confirming two-wheelers as the highest-risk category ([morth.nic.in](https://morth.nic.in)). First-mover platforms can frame compliance as product quality rather than retrofit. `[LIT]`

**3. Driver retention is the highest-leverage cost variable in last-mile unit economics.** At an estimated 25–30% monthly churn `[EST]`, replacing one driver costs approximately 1.5–2× their monthly earnings in recruiting, onboarding, and productivity ramp — structured estimate; method detailed in Appendix C. The relationship between NPS improvement and churn reduction in platform businesses is documented by Bain's NPS research ([bain.com/insights/topics/loyalty](https://www.bain.com/insights/topics/loyalty/)), though no specific delivery platform NPS-to-churn correlation has been found in publicly available research.

---

## 2. Goals & Non-Goals

### 2.1 Goals

1. Reduce cognitive load during active delivery by replacing tap-heavy flows with voice commands
2. Reduce inbound driver support tickets by ≥25% vs. baseline (baseline to be established via CRM query in Phase 0) within 6 months of full rollout
3. Improve driver safety by eliminating phone-in-hand interactions while in motion
4. Increase order completion rate among new drivers (tenure <30 days) by ≥8%
5. Improve Driver NPS by ≥12 points within 9 months

### 2.2 Non-Goals (v1)

- Voice features for customers (ordering, tracking)
- Deep personalisation / proactive coaching (v2 roadmap)
- Autonomous issue resolution without human-in-the-loop (v2)
- Full in-app turn-by-turn navigation (handled via maps deep-link in v1; native integration v2)
- EV battery optimisation voice commands (v3 roadmap)

---

## 3. User Personas

> Constructed from ride-along field research `[OBS]` and interview data `[INT]`. Names are illustrative archetypes.

### Persona 1: "The New Arrival" — New Driver (tenure < 60 days)

**Profile:** Early 20s, migrant worker, major metro, primary language different from the city's dominant language, uses earphones while riding, entry-to-mid Android device
**Mental model:** Anxious about wrong addresses, afraid to call support (feels judged), low app fluency
**Pain points:**
- Spends 3–5 extra minutes per order re-confirming delivery location `[OBS]`
- Misses OTP prompts while navigating — has to re-open app to retrieve `[OBS]`
- Does not know how to escalate issues (merchant delay, address mismatch) without calling support `[INT]`

**Voice AI opportunity:** Step-by-step spoken navigation confirmation, proactive OTP readout at drop, issue escalation by voice with no typing

---

### Persona 2: "The Optimizer" — Veteran Driver (tenure > 1 year, 12+ orders/day)

**Profile:** Mid-30s, city native, multilingual, efficiency-oriented, Bluetooth headset, sometimes manages a second driver in the household
**Mental model:** Efficiency-obsessed; resents any redundant app step as a tax on earnings
**Pain points:**
- Manual status taps feel performative when GPS already confirms location `[INT]`
- Mentally managing 2+ concurrent orders; loses sequencing when forced to open app `[OBS]`
- Cash-on-delivery confirmation flows are disproportionately slow `[INT]`

**Voice AI opportunity:** Hands-free status updates, multi-order sequencing narration, faster confirmation loops

---

### Persona 3: "The Fleet Rider" — EV Driver (electric two-wheeler, fleet or rental)

**Profile:** Late 20s, 15–18 orders/day, platform-partnered EV, more tech-comfortable, in-dash display + earbuds
**Mental model:** Managing range anxiety and delivery pressure simultaneously; frustrated by absence of EV-specific app features
**Pain points:**
- No in-app awareness of charging stations on route `[INT]`
- No spoken alert before accepting a far order when battery is sub-20% `[INT]`
- Fleet check-in/check-out is manual and time-consuming `[OBS]`

**Voice AI opportunity:** Spoken range-aware route suggestions, shift start/end by voice, proactive battery alerts before order acceptance

---

### Persona 4: "The Elder" — Senior Driver / Informal Mentor (tenure 3+ years)

**Profile:** Early 40s, 3+ years on platform, informally mentors new drivers in the zone, Bluetooth helmet, pride in professionalism
**Pain points:**
- Escalation flows require typing on a busy street; humiliating during a dispute `[INT]`
- Wants real-time earnings visibility without stopping to open the app `[INT]`

**Voice AI opportunity:** Earnings narration on demand, spoken dispute filing, shift-end summary narrated at day's end

---

## 4. User Stories

### 4.1 Core Navigation & Order Flow

| ID | As a driver... | I want to... | So that... |
|---|---|---|---|
| US-01 | New driver | Hear the delivery address spoken aloud with a landmark at order assignment | I don't have to squint at the map at every signal |
| US-02 | Any driver | Say a pickup phrase to mark the order as collected | I can confirm pickup while holding the bag |
| US-03 | Any driver | Say an arrival phrase to mark arrival at the drop point | I don't have to unlock the phone just to tap Arrived |
| US-04 | Any driver | Ask "what's the address?" at any point | I can re-hear the destination without unlocking and navigating screens |
| US-05 | Veteran driver | Get spoken ETA updates on demand | I can plan the next order without looking at the screen |

### 4.2 Issue Reporting & Escalation

| ID | As a driver... | I want to... | So that... |
|---|---|---|---|
| US-06 | Any driver | Report "order not ready at merchant" by voice | Support auto-escalates without me typing on a busy street |
| US-07 | Any driver | Report "customer not answering" by voice | The system logs attempted contact and protects me in disputes |
| US-08 | New driver | Ask "what should I do?" when confused | I get contextual voice guidance based on current order state |
| US-09 | Any driver | File a delivery proof report by voice if I drop at gate | Dispute resolution is faster and I'm not penalised unfairly |

### 4.3 Earnings & Shift Management

| ID | As a driver... | I want to... | So that... |
|---|---|---|---|
| US-10 | Any driver | Ask "how much have I earned today?" | I can gauge whether to take another order or sign off |
| US-11 | EV driver | Be told range status before accepting a far order | I don't run out mid-delivery |
| US-12 | Veteran driver | Say "taking a break" by voice | My status updates without tapping |

---

## 5. Feature Specification

### 5.1 Activation

**Wake phrase:** A short, distinct phrase in the primary market language (2 syllables preferred; must not appear in common ambient speech)
**Fallback activation:** Hardware shortcut (e.g. volume down × 2 while app is active) for high-noise environments
**Always-on mode:** Optional; default OFF; auto-enables when an order is active and driver is in-motion (accelerometer + GPS velocity signal)
**Language support (v1):** Minimum 2 languages covering primary and most common secondary driver languages. Code-switching (mixing two languages mid-sentence) must be handled — drivers do not stop code-switching on command.

**Key constraints:**
- Must function at 70 dB+ ambient noise (urban traffic, rain)
- Response latency: <1.2 seconds end-to-end (P90)
- Offline fallback for core commands when connectivity falls below 2G threshold

---

### 5.2 Command Taxonomy

#### Category A: Order Lifecycle (High frequency — must-have v1)

| Intent | Example phrasings to recognise | Action triggered |
|---|---|---|
| Confirm pickup | "picked it up", "got the order", "collected" | Marks order Picked Up |
| Mark arrived at drop | "I'm here", "arrived", "reached" | Marks Arrived at Drop |
| Confirm delivery | "delivered", "handed over", "done" | Marks Delivered; initiates OTP flow via voice |
| Hear OTP | "what's the OTP?", "tell me the code" | Reads customer OTP aloud |
| Repeat address | "what's the address?", "where am I going?" | Re-reads drop address + nearest landmark |

#### Category B: Issue Reporting (Medium frequency — v1)

| Intent | Action triggered |
|---|---|
| Merchant not ready | Logs merchant delay; auto-triggers SLA timer and support alert if wait exceeds threshold |
| Customer not answering | Logs contact attempt; unlocks "safe drop" flow via voice |
| Cancel order | Initiates cancellation flow with spoken confirmation before executing |
| General help | Reads top 3 probable issues based on current order state |

#### Category C: Earnings & Shift (Lower frequency — v1)

| Intent | Action triggered |
|---|---|
| Check earnings | Reads shift earnings, bonuses, incentives achieved vs. target |
| Go on break | Sets status to Break (pauses order assignment) |
| Return from break | Sets status to Active |
| End shift | Initiates shift-end flow with spoken earnings summary and confirmation |

#### Category D: Navigation Assist (Maps deep-link — v1)

| Intent | Action triggered |
|---|---|
| Start navigation | Launches navigation via configured maps deep-link |
| Check distance | Reads remaining distance + ETA |
| Check traffic | Reads current traffic condition on route |

---

### 5.3 Dialogue Design Principles

1. **Brevity first.** Responses cap at 2 sentences. Addresses not read unsolicited — only on request or at specific lifecycle moments.
2. **Confirmation loops only for irreversible actions.** Cancel and End shift require spoken "yes, confirm" before executing. All other commands execute immediately.
3. **Graceful error recovery.** If unrecognised: "Didn't catch that, please say it again." Never silent failure.
4. **Proactive narration at key moments.** System speaks unprompted when: order is ready at merchant, driver is within 200m of drop, an incentive milestone is 1–2 orders away, or EV battery falls below 20% during an active delivery.
5. **Transparent handoffs.** Before connecting to a human agent: "Connecting you to support now, one moment." Driver is never dropped into hold without warning.

---

### 5.4 AI Model Architecture (High-Level)

```
[Driver voice input]
        ↓
[On-device noise suppression + Voice Activity Detection]
        ↓
[Speech-to-text — multilingual ASR, market-appropriate provider]
        ↓
[Intent classification — fine-tuned on delivery driver utterances]
        ↓
[Context engine — current order state + driver profile + session history]
        ↓
[Action resolver — maps intent to API call or dialogue response]
        ↓
[Text-to-speech — natural-sounding voice in driver's language]
        ↓
[Spoken output to driver]
```

**Offline mode:** Core commands are cached locally at order assignment (address, OTP, status update endpoints). Work on 2G fallback. Issue filing and support escalation require connectivity.

**Confidence thresholding:** If ASR + intent classification confidence falls below a configurable threshold (suggested starting point: 0.70), the system asks the driver to repeat rather than executing a wrong action. Calibrate empirically during the dark store pilot.

---

## 6. Success Metrics

### 6.1 North Star Metric

**Voice command task completion rate (TCR):** % of voice-initiated interactions that result in the correct system state change without fallback to manual tap.

**Target:** ≥82% TCR at 90 days post-launch

*Why this metric:* TCR captures both ASR accuracy and dialogue design quality in a single number. A driver who gives up and taps is a failed voice interaction regardless of whether ASR heard them correctly.

---

### 6.2 Primary Metrics

| Metric | Baseline source | 90-day target | 180-day target |
|---|---|---|---|
| Voice command TCR | — (new metric) | ≥82% | ≥88% |
| Driver support tickets / 100 orders | `[LOG]` | –25% vs. baseline | –35% vs. baseline |
| Avg. taps per order | `[OBS]` 8–11 | 5–7 | 4–6 |
| New driver order completion rate (D1–D30) | `[LOG]` | +8% vs. control | +12% vs. control |
| Driver NPS | `[INT]` quarterly pulse | +8 points | +12 points |

### 6.3 Secondary Metrics

- Voice command response latency <1.2s P90 `[LOG]`
- Error recovery rate — % of failed commands recovered via retry; target >60% `[LOG]`
- Feature adoption — % of drivers using voice ≥3×/week at 60 days; target 40% `[LOG]`
- Safety proxy: self-reported near-miss incidents per 1,000 deliveries (directional; not attributable to voice AI alone in v1) `[INT]`
- Incentive awareness: % drivers who correctly state incentive gap at shift-end; target +30% vs. baseline `[INT]`

### 6.4 Guardrail Metrics (Must Not Regress)

- Order delivery time (SLA): must not increase >2% vs. control group
- Driver app crash rate: must not increase vs. pre-launch baseline
- Mobile data overhead: must not exceed +12 MB/driver/day
- Cancellation rate: must not increase >0.5% in pilot cohort

---

## 7. Launch Plan

### Phase 0: Research & Instrumentation (Weeks 1–4)

**Goal:** Establish baselines before building. Do not skip this phase.

- [ ] **Field research:** 40 ride-alongs across target city, all driver archetypes, 3 zone types. Focus on screen interaction moments. `[OBS]`
- [ ] **Utterance corpus:** Collect 2,000 labelled voice samples in 2 target languages — natural delivery-context phrases, not prompted reads. Used for ASR fine-tuning and intent model training.
- [ ] **Baseline instrumentation:** Log taps per order stage, time-between-taps, support call triggers, time-to-complete by order state. This is the measurement foundation — do not launch without it. `[LOG]`
- [ ] **Wizard-of-Oz prototype:** Recruit 20 drivers; simulate voice responses via a human operator. Test whether drivers will engage with voice at all before the model is built. `[OBS]`
- [ ] **Safety & legal audit:** Policy and legal sign-off on scope, data retention, and voice recording compliance per target market.

### Phase 1: Dark Store Pilot (Weeks 5–10)

**Scope:** 2 dark stores / driver staging hubs in the launch city
**Drivers:** 80 opt-in; 80 matched control (same zone, similar tenure distribution)
**Activation:** Feature flag; explicit driver opt-in with consent
**Languages:** Primary market language only
**Exit criteria to Phase 2:**
- TCR ≥75% on core Category A commands
- No safety regressions (crash rate, SLA)
- Driver satisfaction with voice feature ≥3.8/5.0 on in-app rating

### Phase 2: City Pilot (Weeks 11–20)

**Scope:** All zones, launch city
**Drivers:** ~20% of city fleet; opt-in with participation incentive
**Languages added:** Secondary market language
**New features:** Earnings narration, incentive proximity alerts, EV range announcements
**Exit criteria to Phase 3:**
- TCR ≥80%
- Support ticket reduction ≥18%
- No SLA regression

### Phase 3: Multi-City Rollout (Weeks 21–36)

**Scope:** 4–5 cities in order of fleet size
**Drivers:** All new onboarding drivers get voice as default; existing drivers opt in
**A/B test:** New driver onboarding — voice-first vs. tap-first; measure D7/D30 retention and early order completion rate

### Phase 4: National Default (Week 37+)

**Scope:** All cities, all drivers
**Activation:** Voice AI on by default; driver can opt out
**v2 unlocked:** Proactive coaching, fleet/partner integrations

---

## 8. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| ASR accuracy degrades in high-noise environments | High | High | On-device noise suppression; offline fallback for core commands; haptic confirmation as fallback channel |
| Low adoption among less tech-comfortable drivers | Medium | High | In-person onboarding at pilot dark stores; peer ambassador program; first-week participation incentive |
| False positive commands (ambient conversation triggers action) | Medium | Medium | Wake-phrase gate + 0.5s pause before command window; spoken confirmation required for all irreversible actions |
| Driver privacy concerns about voice recording | Medium | High | On-device processing for core commands; explicit opt-in with plain-language consent; zero audio retention post-session |
| NLP hallucination in issue reports leading to wrong escalations | Low | High | Human review of all AI-filed issue reports in Phase 1; escalation to agent if confidence <0.70; driver always can override manually |
| Regulatory challenge framing voice use as distracted driving | Low | High | Proactive regulator engagement; position product as hands-free alternative to current phone-in-hand behaviour; commission independent safety study |
| Competitor ships equivalent feature during pilot | Medium | Medium | Speed to dark store; driver loyalty flywheel — NPS improvement is a moat if the product is genuinely better |

---

## 9. Open Questions

1. **Maps integration:** Deep-link to third-party maps (faster to ship) vs. native in-app turn-by-turn with voice (higher quality, 3–6 months longer). Decision needed by Week 3.
2. **Opt-in vs. default-on at Phase 2:** Voice data collection implicates data protection legislation in most markets. DPO sign-off on lawful basis required before Phase 2 scale.
3. **Confidence threshold:** At what score do we ask the driver to repeat vs. silently fall back to app? Starting point 0.70 — calibrate from Phase 1 data.
4. **Incentive design for adoption:** Flat weekly bonus for usage threshold vs. gamified "voice streak" — which produces lower feature churn? A/B in Phase 2.
5. **Driver-to-driver voice relay:** Should drivers be able to voice-message each other for handoff cases (parking, access codes)? Deferred to v2 but worth scoping now.

---

## 10. Appendix

### A. Research Plan Summary

| Method | Sample | Timing | Owner |
|---|---|---|---|
| Ride-along field observation | 40 drivers, 3 zone types | Phase 0 | PM + UX Researcher |
| Semi-structured interviews | 60 drivers (20 per tenure tier) | Phase 0 + Phase 1 debrief | UX Researcher |
| Utterance corpus collection | 2,000 labelled samples, 2 languages | Phase 0 | ML team + PM |
| Wizard-of-Oz prototype | 20 drivers | Phase 0 weeks 3–4 | PM + Engineering |
| In-app tap event logging | All drivers in pilot | Phase 1 onward | Engineering |
| In-app satisfaction rating | Pilot cohort | Phase 1 onward | PM |

### B. Technical Dependencies

- Multilingual ASR provider evaluation (assess: WER at 70dB ambient, latency, cost per minute, offline capability, regional language coverage)
- Natural-sounding TTS in target languages (assess: naturalness MOS score, latency, speaker diversity)
- Driver app offline caching infrastructure for order-assigned state
- Support ticket system webhook API for voice-filed issue reports
- Data protection legal review per market prior to Phase 2

### C. Unit Economics Estimate — Driver Replacement Cost

The claim that replacing one churned driver costs ~1.5–2× monthly earnings is a structured estimate `[EST]`. The cost structure below is based on general industry logic and is consistent with churn cost analysis published by last-mile logistics operators (see [spoke.com/dispatch/blog/last-mile-delivery-challenges](https://spoke.com/dispatch/blog/last-mile-delivery-challenges)):

| Cost component | Basis |
|---|---|
| Recruiting (referral bonus or acquisition cost) | Industry range: typically 0.2–0.5× first-month earnings equivalent `[EST]` |
| Onboarding (training, kit, documentation, background check) | Typically 0.3–0.5× first-month earnings equivalent `[EST]` |
| Productivity ramp (new driver completes ~60–70% of experienced driver order volume in first 30 days) | `[HYPO]` — consistent with general onboarding ramp patterns in gig logistics |
| Management time (zone supervisor onboarding hours) | `[EST]` 3–4 hours per new driver at supervisor loaded cost |


### D. Glossary

| Term | Definition |
|---|---|
| TCR | Task Completion Rate — % of voice commands resulting in correct system state change |
| WER | Word Error Rate — ASR accuracy metric; lower is better |
| Dark store | Platform-operated micro-fulfilment or driver staging hub |
| VAD | Voice Activity Detection — determines when driver is speaking vs. ambient noise |
| ASR | Automatic Speech Recognition |
| TTS | Text-to-Speech |
| MOS | Mean Opinion Score — standard TTS naturalness metric (1–5 scale) |
| Wizard-of-Oz | Research method where a human simulates AI responses to test user behaviour before the AI is built |
| Code-switching | Moving between two languages mid-sentence; common in multilingual urban markets |
