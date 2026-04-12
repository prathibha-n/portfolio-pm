-- ============================================================
-- Ridehailing India — EV Transition: Driver Cohort & Scoring Query
-- 1: EV-eligible driver targeting
-- ============================================================
-- Purpose:
--   Segments active non-EV drivers into conversion tiers using
--   behavioural proxies for suppressed EV intent:
--     - trip distance (natural EV use case)
--     - city-centre density (route predictability)
--     - daily trip volume + peak-hour share (financial motivation)
--     - tenure + vehicle age (cash-constraint / loan candidate)
--
-- Output: city × tier rollup with sub-segment counts for
--         incentive budget allocation
-- ============================================================

-- ============================================================
-- SCHEMA (mock — 90-day rolling window)
-- ============================================================

-- drivers(
--   driver_id        UUID        PK,
--   city             VARCHAR,    -- 'BLR','MUM','DEL','HYD','CHN'
--   vehicle_year     INT,        -- manufacturing year
--   vehicle_type     VARCHAR,    -- 'petrol','diesel','cng','ev'
--   onboarding_date  DATE,
--   is_active        BOOLEAN
-- )

-- trips(
--   trip_id          UUID        PK,
--   driver_id        UUID        FK → drivers,
--   trip_date        DATE,
--   trip_count       INT,        -- trips completed that day
--   avg_dist_km      FLOAT,      -- avg distance per trip that day
--   city_centre_pct  FLOAT,      -- share of trips in central zones (0–1)
--   peak_hour_pct    FLOAT       -- share of trips in 7–10am / 5–9pm
-- )
-- Note: daily granularity lets you compute rolling 90-day averages without
-- blowing up the join. trip_count per day is more reliable than counting
-- trip_id rows (drivers occasionally have data gaps).


-- charging_events(
--   event_id         UUID        PK,
--   driver_id        UUID        FK → drivers,
--   event_date       DATE,
--   charge_duration_min INT,
--   charge_location  VARCHAR     -- 'home','public_fast','public_slow','workplace'
-- )
-- Note: used to check whether existing EV drivers cluster charges at specific
-- location types. Informs hub placement (for future use); not used in scoring below.

-- ============================================================



WITH driver_behaviour AS (
  SELECT
    d.driver_id,
    d.city,
    (EXTRACT(YEAR FROM CURRENT_DATE) - d.vehicle_year) AS vehicle_age_yrs,
    DATEDIFF(CURRENT_DATE, d.onboarding_date) / 30.0   AS tenure_months,
    AVG(t.trip_count)      AS avg_daily_trips,
    AVG(t.avg_dist_km)     AS avg_trip_dist_km,
    AVG(t.city_centre_pct) AS city_centre_share,
    AVG(t.peak_hour_pct)   AS peak_hour_share
  FROM drivers d
  JOIN trips t USING (driver_id)
  WHERE t.trip_date >= CURRENT_DATE - 90
    AND d.is_active   = TRUE
    AND d.vehicle_type != 'ev'   -- exclude already-converted drivers
  GROUP BY 1, 2, 3, 4
),

  

scored AS (
  SELECT
    driver_id,
    city,
    vehicle_age_yrs,
    tenure_months,
    avg_daily_trips,
    avg_trip_dist_km,
    city_centre_share,
    peak_hour_share,

    -- Proxy 1: natural EV use case
    --   Short trips + city-centre density = well within EV range, near likely charging infrastructure. Gap vs conversion = suppressed intent.
    avg_trip_dist_km  <= 12
      AND city_centre_share >= 0.6                AS natural_ev_profile,

    -- Proxy 2: financial motivation 
    --   Peak-hour earners respond most strongly to earnings guarantees.
    avg_daily_trips   >= 8
      AND peak_hour_share   >= 0.5                AS financially_motivated,

    -- Proxy 3: cash-constrained / loan candidate
    --   Long-tenured driver on an aging vehicle without upgrading = capital barrier, not intent barrier. Loan tie-up is the unlock.
    tenure_months     >= 24
      AND vehicle_age_yrs   >= 4                  AS likely_cash_constrained,

    -- Tier assignment
    --   Tier 1: strongest behavioural case for EV + platform commitment
    --   Tier 2: partial signal — worth nurturing with lighter incentive
    --   Tier 3: insufficient signal — referral / awareness only
    CASE
      WHEN avg_trip_dist_km  <= 12
       AND city_centre_share >= 0.6
       AND avg_daily_trips   >= 8
       AND tenure_months     >= 6    THEN 'tier_1'
      WHEN avg_trip_dist_km  <= 18
       AND city_centre_share >= 0.45
       AND avg_daily_trips   >= 5
       AND tenure_months     >= 3    THEN 'tier_2'
      ELSE                               'tier_3'
    END AS ev_tier

  FROM driver_behaviour
)

-- City-level rollup — feeds incentive budget model
-- Each sub-segment count maps to a different incentive lever:
--   natural_ev_fit      → charging-finder feature sufficient
--   peak_earners        → earnings guarantee closes the deal
--   loan_candidates     → 0% interest EV loan tie-up is the unlock
SELECT
  ev_tier,
  city,
  COUNT(*)                              AS driver_count,
  COUNTIF(natural_ev_profile)           AS natural_ev_fit,
  COUNTIF(financially_motivated)        AS peak_earners,
  COUNTIF(likely_cash_constrained)      AS loan_candidates,
  ROUND(AVG(avg_trip_dist_km),   1)     AS avg_trip_dist_km,
  ROUND(AVG(city_centre_share) * 100, 1) AS avg_city_centre_pct
FROM scored
GROUP BY 1, 2
ORDER BY
  CASE ev_tier
    WHEN 'tier_1' THEN 1
    WHEN 'tier_2' THEN 2
    ELSE 3
  END,
  driver_count DESC;

-- ============================================================
-- Threshold sensitivity (adjust to match driver distribution):
--
--   avg_trip_dist_km  <= 12   → loosen to 18 to expand Tier 1 ~40%
--   city_centre_share >= 0.6  → loosen to 0.45 for suburban markets
--   avg_daily_trips   >= 8    → tighten to 10 for high-value-only pilots
--   tenure_months     >= 6    → loosen to 3 if driver base is younger

-- ============================================================
