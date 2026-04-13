# Beauty Ecommerce — Retention Cohort Teardown

A PM-led analysis of customer retention in a beauty ecommerce vertical — looking at where users drop off, which segments are worth investing in, and what a re-engagement strategy grounded in data actually looks like.

---

## Context

Retention analysis is a core PM skill — but most of it in practice gets reduced to "send a push notification on Day 7." This project is an attempt to go deeper: build the cohort model from scratch, interrogate the data properly, and derive strategies that are specific enough to actually act on.

---

## What I Did

- Designed a simulated beauty ecommerce dataset — 5,000 customers, 6 signup cohorts (Sep 2024 – Feb 2025), across 5 product categories (Health & Beauty, Makeup, Haircare, Personal Care, Fragrance) and 5 acquisition channels (Google Search, Instagram / Meta Paid, Influencer & Creator, App Organic, Referral Program)
- Built a SQL cohort model using CTEs to compute D7 / D30 / D90 retention rates broken down by signup month, acquisition channel, and first-order category
- Identified the two highest-signal drop-off segments and formed hypotheses for each — one driven by purchase intent at acquisition, one by product replenishment cycle
- Derived a category-level retention strategy — each category has a different replenishment behaviour and needs a different re-engagement mechanic
- Built a channel strategy — ranking channels by retention quality and examining where each channel is being used well vs where it is misallocated
- Designed a lifecycle segmentation framework — New / Returning / Veteran users with distinct goals and success metrics per stage
- Framed an experiment roadmap with specific hypotheses to test, including how to measure incremental impact correctly using a control group

The dataset is synthetic but calibrated to realistic beauty ecommerce behaviour. The schema mirrors the public [Olist ecommerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and can be swapped for real data.

---

## How to Read This Repo

**Start with the insight doc. Use the charts as reference. Open the notebook only if you want to see the SQL.**

| File | What it is |
|---|---|
| `beauty_retention_insights.md` | The main deliverable — findings, category strategy, channel strategy, lifecycle segmentation, and experiment design |
| `chart1_cohort_heatmap.png` | Overall retention by cohort month |
| `chart2_channel_retention.png` | D7 / D30 / D90 retention by acquisition channel |
| `chart3_category_retention.png` | D7 / D30 / D90 retention by first-order category |
| `chart4_channel_category_heatmap.png` | D30 retention across all channel × category combinations |
| `chart5_retention_curves.png` | Retention decay curves per channel |
| `retention_rates.csv` | Full output table — all retention rates by signup month, channel, and category |
| `beauty_retention_cohort.ipynb` | The notebook — simulation, SQL cohort model, chart generation |
