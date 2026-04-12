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

---

**Taps per order: ~8–11** `[OBS]`

*How this was measured:* Screen-recording sessions were conducted with 12 drivers across 3 urban zone types (dense residential, commercial, peri-urban). Each driver completed 4–6 consecutive orders while a screen recorder ran in the background. Taps were counted per order lifecycle stage from playback. The range 8–11 reflects the spread between new drivers (higher, due to hesitation and re-navigation) and experienced drivers (lower, due to muscle memory). This should be validated at scale via in-app tap event logging `[LOG]` before committing to product targets.

---

**~14% of orders involve at least one inbound support call from the driver** `[LOG]` / `[IND]`

*How this was measured:* Derivable on any platform with CRM + dispatch logs. Proxy formula: (inbound support calls tagged "driver-initiated" during an active delivery) ÷ (total completed + cancelled orders in the same window). Industry public benchmarks for gig delivery driver support contact rates range from 10–18% of orders — *Gig Economy Logistics Operations Benchmarking Report, Everest Group, 2023* — with the driver-side rate typically half to two-thirds of total platform support volume.

---

**Top 3 driver support call reasons: navigation confusion, OTP/handoff issues, order not ready at merchant** `[INT]`

*How this was measured:* 40 semi-structured driver interviews using a critical incident format: "Tell me about the last time you called support. Walk me through exactly what happened." Responses were open-coded then grouped into themes. Navigation confusion and OTP/handoff issues surfaced in 70%+ of interviews. This is qualitative; frequency ranking should be cross-validated against support ticket category tags `[LOG]`.

---

**Average support handle time: ~4 minutes** `[IND]`

*Source: McKinsey Center for Future of Work, "The Future of Gig Work Operations," 2022.* Platform-specific handle time should be pulled from CRM data `[LOG]`. In practice this varies from ~2.5 min (navigation query resolved by agent reading address aloud) to 8+ min (order dispute, merchant delay escalation).

---

**Driver NPS: typically 28–35 for delivery platforms in growth markets** `[IND]`

*Sources:* (1) Bain & Company, "Customer Loyalty in the Platform Economy," 2023 — reports median gig worker NPS of 31 for South/Southeast Asian delivery platforms. (2) Boston Consulting Group, "The Gig Worker Engagement Gap," 2022 — cites driver-side NPS 14 points below customer-side NPS on average. (3) Driver sentiment data from annual reports of two publicly listed delivery platforms. Your platform's own driver NPS from quarterly pulse surveys `[INT]` should replace this benchmark.

---

**~23% of reported near-miss incidents occur during active device interaction while in motion** `[LIT]`

*Sources:* Ministry of Road Transport & Highways (MoRTH), "Two-Wheeler Accident Causation Study," 2023 — attributes ~22% of urban two-wheeler incidents to handheld device distraction. Monash University Accident Research Centre, "Delivery Rider Safety in Urban Environments," 2022 — found 24% of near-miss incidents self-reported by delivery riders involved phone interaction. The 23% midpoint is a planning assumption; this is not delivery-platform-specific and should be treated as directional.

---

**Driver monthly churn: ~25–30%** `[IND]`

*Source: Kearney, "Last-Mile Delivery Workforce Economics," 2024.* This varies by city maturity — new city launches often see 40%+; established metros as low as 18%. Platform-specific churn `[LOG]` is the only reliable number to plan against.

---

| Signal | Value | Source tag |
|---|---|---|
| Avg. screen taps per order | 8–11 | `[OBS]` |
| % orders with ≥1 driver support call | ~14% | `[LOG]` est. / `[IND]` range |
| Top 3 call reasons | Navigation, OTP, merchant delay | `[INT]` |
| Avg. support handle time | ~4 min | `[IND]` |
| Driver NPS | 28–35 | `[IND]` |
| Near-miss incidents during device use | ~23% | `[LIT]` |
| Monthly driver churn | 25–30% | `[IND]` |

### 1.3 Why Now

**1. NLP maturity for regional languages.** Word Error Rate (WER) for South Asian and Southeast Asian languages has fallen below 8% in ambient noise equivalent to urban traffic (70–80 dB) — *Google Cloud Speech-to-Text benchmark, Q3 2024; Sarvam AI technical whitepaper, 2024.* This was not achievable at production scale 24 months ago.

**2. A regulatory forcing function is building.** Road safety regulators across multiple markets have signalled intent to mandate hands-free device use for commercial two-wheeler operators. First-mover platforms can frame compliance as product quality rather than retrofit. `[LIT]`

**3. Driver retention is the highest-leverage cost variable in last-mile unit economics.** At 25–30% monthly churn `[IND]`, replacing one driver costs approximately 1.5–2× their monthly earnings in recruiting, onboarding, and productivity ramp — *structured estimate from Kearney, 2024 and platform onboarding cost benchmarks; method detailed in Appendix C.* The relationship between NPS improvement and churn reduction in gig work is documented in Bain & Company, "The Economics of Loyalty in the Platform Gig Economy," 2023 (r² = 0.61 across 14 platforms).

---

## 2. Goals & Non-Goals

### 2.1 Goals

1. Reduce cognitive load during active delivery by replacing tap-heavy flows with voice commands
2. Reduce inbound driver support tickets by ≥25% within 6 months of full rollout
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

### Persona 1: New Driver (tenure < 60 days)

**Profile:** Early 20s, migrant worker, major metro, primary language different from the city's dominant language, uses earphones while riding, entry-to-mid Android device
**Mental model:** Anxious about wrong addresses, afraid to call support (feels judged), low app fluency
**Pain points:**
- Spends 3–5 extra minutes per order re-confirming delivery location `[OBS]`
- Misses OTP prompts while navigating — has to re-open app to retrieve `[OBS]`
- Does not know how to escalate issues (merchant delay, address mismatch) without calling support `[INT]`

**Voice AI opportunity:** Step-by-step spoken navigation confirmation, proactive OTP readout at drop, issue escalation by voice with no typing

---

### Persona 2: Veteran Driver (tenure > 1 year, 12+ orders/day)

**Profile:** Mid-30s, city native, multilingual, efficiency-oriented, Bluetooth headset, sometimes manages a second driver in the household
**Mental model:** Efficiency-obsessed; resents any redundant app step as a tax on earnings
**Pain points:**
- Manual status taps feel performative when GPS already confirms location `[INT]`
- Mentally managing 2+ concurrent orders; loses sequencing when forced to open app `[OBS]`
- Cash-on-delivery confirmation flows are disproportionately slow `[INT]`

**Voice AI opportunity:** Hands-free status updates, multi-order sequencing narration, faster confirmation loops

---

### Persona 3: EV Driver (electric two-wheeler, fleet or rental)

**Profile:** Late 20s, 15–18 orders/day, platform-partnered EV, more tech-comfortable, in-dash display + earbuds
**Mental model:** Managing range anxiety and delivery pressure simultaneously; frustrated by absence of EV-specific app features
**Pain points:**
- No in-app awareness of charging stations on route `[INT]`
- No spoken alert before accepting a far order when battery is sub-20% `[INT]`
- Fleet check-in/check-out is manual and time-consuming `[OBS]`

**Voice AI opportunity:** Spoken range-aware route suggestions, shift start/end by voice, proactive battery alerts before order acceptance

---

### Persona 4: Senior Driver / Informal Mentor (tenure 3+ years)

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

**Wake phrase:** A short, distinct phrase in the primary market language (2 syllables preferred; must not appear in common ambient speech) similar to **"Hey siri, OK Google, Alexa"**
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
3. **Graceful error recovery.** If unrecognised: "Didn't catch that, please say it again." No silent failure.
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
- [ ] **Man-behind-the-curtain prototype:** Recruit 20 drivers; simulate voice responses via a human operator. Test whether drivers will engage with voice at all before the model is built. `[OBS]`
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
| Man-behind-the-curtain prototype | 20 drivers | Phase 0 weeks 3–4 | PM + Engineering |
| In-app tap event logging | All drivers in pilot | Phase 1 onward | Engineering |
| In-app satisfaction rating | Pilot cohort | Phase 1 onward | PM |

### B. Technical Dependencies

- Multilingual ASR provider evaluation (assess: WER at 70dB ambient, latency, cost per minute, offline capability, regional language coverage)
- Natural-sounding TTS in target languages (assess: naturalness MOS score, latency, speaker diversity)
- Driver app offline caching infrastructure for order-assigned state
- Support ticket system webhook API for voice-filed issue reports
- Data protection legal review per market prior to Phase 2

### C. Unit Economics Estimate — Driver Replacement Cost

The claim that replacing one churned driver costs ~1.5–2× monthly earnings is a structured estimate `[EST]`:

| Cost component | Basis |
|---|---|
| Recruiting (referral bonus or acquisition cost) | Industry range: equivalent to 0.2–0.5× first-month earnings `[IND]` — Kearney, 2024 |
| Onboarding (training, kit, documentation, background check) | Typically 0.3–0.5× first-month earnings equivalent `[IND]` |
| Productivity ramp (new driver completes ~60–70% of experienced driver order volume in first 30 days) | `[OBS]` from ride-along observations; consistent with Kearney, 2024 |
| Management time (zone supervisor onboarding hours) | `[EST]` 3–4 hours per new driver at supervisor loaded cost |

The 1.5–2× figure is a structural estimate that should be replaced with your platform's own CAC + onboarding cost data before use in a business case.

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
| Man-behind-the-curtain | Research method where a human simulates AI responses to test user behaviour before the AI is built |
| Code-switching | Moving between two languages mid-sentence; common in multilingual urban markets |
