# Voice AI for Last-Mile Delivery Drivers — Product Work Sample

This folder contains a product management work sample: a full PRD and supporting artefacts for a voice AI assistant designed to reduce cognitive load and safety risk for delivery drivers on two-wheelers.

---

## What this is
 
A speculative PRD for a voice AI assistant for last-mile delivery drivers on two-wheelers. The core problem: delivery driver apps were designed for someone sitting still. Drivers use them one-handed, in traffic, under time pressure, often in a second language. This explores what a voice-first interface for that context would look like — from the AI architecture to the driver dialogue to the launch plan.
 
The product is intentionally generic — no platform, company, or AI system is named. It is written to apply across any last-mile delivery ecosystem (quick commerce, logistics, ride-hailing, gig delivery).

---

## Files

| File | What it is | Link |
|---|---|---|
| `PRD.md` | Full product requirements document (~500 lines) | [Link to PRD](https://github.com/prathibha-n/portfolio-pm/blob/main/prd-voice-ai-captain/PRD.md) |
| `user-journey.drawio.png` | User journey map image — created in draw.io | [Link to User Journey Map](https://github.com/prathibha-n/portfolio-pm/blob/main/prd-voice-ai-captain/user-journey-captain.png) |

---

## PRD structure at a glance

The PRD covers:

1. **Problem statement** — the interface-context mismatch for drivers operating one-handed under load
2. **Evidence base** — 7 quantitative signals, each with source tag, basis, and validation method
3. **Goals and non-goals** — v1 scope with explicit deferral rationale for v2/v3
4. **User personas** — four archetypes (new driver, veteran, EV fleet rider, senior mentor)
5. **User stories** — 12 stories across order lifecycle, issue reporting, and shift management
6. **Feature specification** — activation model, command taxonomy (4 categories, ~20 intents), dialogue design principles, high-level AI architecture
7. **Success metrics** — north star (task completion rate), primary metrics, secondary metrics, and guardrail metrics
8. **Launch plan** — four phases from dark store pilot to national default, with explicit exit criteria at each gate
9. **Risks and mitigations** — 7 risks with likelihood/impact ratings
10. **Appendix** — research plan, technical dependencies, unit economics estimate with full decomposition, glossary

---

## Data sourcing methodology

Every number in the PRD carries one of seven source tags:

| Tag | Meaning |
|---|---|
| `[HYPO]` | Hypothesis — not yet observed; basis and validation method described inline |
| `[OBS]` | Direct observational research — ride-alongs, screen recordings |
| `[INT]` | Driver interviews or focus groups |
| `[LOG]` | Platform analytics / server-side log data |
| `[LIT]` | Published third-party research, cited inline |
| `[IND]` | Industry benchmark from public report, cited inline |
| `[EST]` | Structured estimate — basis and method shown inline |

No primary research has been conducted for this document. Figures marked `[HYPO]` are reasoned starting points with a described validation method. Figures marked `[EST]` are structured estimates where no published benchmark was found — the reasoning is shown and a method for replacing the figure with real platform data is given. Where `[LIT]` or `[IND]` is used, a link to the source is included. The intent throughout is to distinguish clearly between what is known, what is estimated, and what needs to be measured — a PRD that cannot be challenged has not been thought through.

---

## Journey map

The journey map covers the full order lifecycle across six stages:

**Order assigned → Ride to merchant → At merchant → Ride to drop → At drop point → Complete order**

For each stage it shows:

- The current tap-heavy flow with tap counts
- The pain point at that stage
- The voice command that replaces the tap interaction
- The proactive (system-initiated) narration that fires without any command
- Persona-level impact across four driver archetypes

---

## Key product decisions documented

**Why voice, not better tap UX?** The problem is not screen design — it's that the driver's hands and eyes are occupied. A redesigned tap flow is still a tap flow. The constraint is physical, not navigational.

**Why default-off in v1?** Voice data collection implicates data protection legislation in most markets. Opt-in with explicit consent is the correct default; default-on is a Phase 4 decision made with DPO sign-off after demonstrated safety benefit.

**Why a dark store pilot before city rollout?** The utterance distribution in the wild is unknown. Fine-tuning ASR on 2,000 collected samples does not guarantee real-world accuracy. A controlled pilot with 80 drivers gives the failure mode data needed before scale.

**Why task completion rate as the north star?** TCR captures both ASR quality and dialogue design quality in one number. A driver who gives up and taps is a failed voice interaction regardless of whether the ASR heard them correctly — and that's the right thing to measure.

---

## What this work sample does not include

- Wireframes or visual design (out of scope for a PRD at this stage)
- A business case with full P&L modelling (unit economics estimate in Appendix C is a starting framework, not a business case)
- Market sizing (the market is the platform's existing driver fleet — TAM analysis would be redundant)
- Competitor feature teardowns (kept generic by design; competitor analysis exists but names platforms)
