-- =============================================================================
-- Rapido: My Route Booking — Experiment Analysis
-- Feature: Preferred destination → increased attractiveness weight in allocation
-- Experiment: A/B test, Delhi and Jaipur
-- Primary metrics: ping rate, acceptance rate, idle time
-- =============================================================================
-- NOTE: Table/column names are illustrative 
-- Outcome numbers (idle time, exact dates) are hypothetical scaffolding.
-- Ping 2× lift and 80% → 90% acceptance are real experiment results.
-- =============================================================================


-- =============================================================================
-- 1. FEATURE ADOPTION — who turned on My Route Booking?
-- =============================================================================
-- CONTEXT: Before measuring impact, we need to know how many drivers
-- actually engaged with the feature. A low adoption rate would mean the
-- experiment result only reflects a small subset, and we'd need to think
-- about discoverability before a full rollout.
-- =============================================================================

SELECT
    city,                                                           -- Total drivers enrolled in the experiment (treatment arm only)
    COUNT(DISTINCT driver_id) AS total_drivers_in_experiment,       -- How many of those drivers actually switched MRB on?
    COUNT(DISTINCT CASE WHEN feature_enabled = true
                        THEN driver_id END) AS mrb_users,

                                                                    -- What % of treatment drivers turned MRB on? (the adoption rate)
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN feature_enabled = true
                                      THEN driver_id END)
          / COUNT(DISTINCT driver_id), 2) AS adoption_rate_pct

FROM experiment_assignments ea                                      -- Pull city from the drivers master table — experiment_assignments only has driver_id 
JOIN drivers d USING (driver_id)
WHERE d.city IN ('Delhi', 'Jaipur')  
  AND ea.variant = 'treatment'                                      -- Only look at treatment group — control drivers never had MRB available, so asking about their "adoption rate" would be meaningless.
  AND ea.experiment_id = 'my_route_booking_v1'                      
GROUP BY 1;


-- =============================================================================
-- 2. CORE RESULT: Ping rate and acceptance rate by variant
--    This is the primary readout — what actually moved.
-- =============================================================================
-- CONTEXT: This is the headline result. We want to know:
--   (a) Ping rate — are treatment drivers getting MORE ride offers per hour online?
--       The feature routes them towards their preferred area, so the allocation
--       algorithm should be offering them more relevant rides.
--   (b) Acceptance rate — are treatment drivers ACCEPTING more of those offers?
--       If they're heading home anyway, they should be more willing to take the ride.
-- Expected result: ~2× ping rate, acceptance up from ~80% to ~90%.
-- =============================================================================

-- Step 1: Build a daily summary per driver (CTE = reusable temp table)
-- NOTE: A CTE (WITH block) is like a named scratch pad. We compute daily
--          driver stats here, then query that scratch pad below. Easier to read
--          than one giant nested query.
WITH driver_daily AS (
    SELECT
        ea.variant,                   -- 'control' or 'treatment'
        e.driver_id,
        d.city,        
        DATE(e.event_time) AS event_date,        
        SUM(online_duration_seconds) / 3600.0  AS hours_online,                          -- Total hours this driver was online that day

        COUNT(CASE WHEN e.event_type = 'ping_received' THEN 1 END)  AS pings_received,  -- How many ride offers (pings) did this driver receive today?

        COUNT(CASE WHEN e.event_type = 'ride_accepted' THEN 1 END)  AS rides_accepted    -- How many rides did the driver actually accept today?


    FROM driver_events e
    JOIN experiment_assignments ea
        ON e.driver_id = ea.driver_id           -- Only include drivers who are part of this experiment
        AND ea.experiment_id = 'my_route_booking_v1'

    JOIN drivers d USING (driver_id)

    WHERE d.city IN ('Delhi', 'Jaipur')
      AND e.event_time BETWEEN '2024-10-01' AND '2024-10-21'
    GROUP BY 1, 2, 3, 4
)

-- Step 2: Aggregate the daily rows up to variant + city level
SELECT
    variant,
    city,
    -- How many unique drivers are in each cell?
    COUNT(DISTINCT driver_id)                                      AS drivers,

    ROUND(SUM(pings_received) / NULLIF(SUM(hours_online), 0), 2)   AS pings_per_hour_online,       -- PING RATE: ride offers per hour online - Expected: treatment ≈ 2× control.
    ROUND(100.0 * SUM(rides_accepted)
          / NULLIF(SUM(pings_received), 0), 2)                     AS acceptance_rate_pct          -- ACCEPTANCE RATE: % of offered rides that were accepted - Expected: control ~80%, treatment ~90%.

FROM driver_daily
GROUP BY 1, 2
ORDER BY city, variant;

-- Expected output (real results):
-- variant    | city   | drivers | pings_per_hour_online | acceptance_rate_pct
-- control    | Delhi  | ~N      | ~X                    | ~80%
-- treatment  | Delhi  | ~N      | ~2X                   | ~90%
-- control    | Jaipur | ~N      | ~X                    | ~80%
-- treatment  | Jaipur | ~N      | ~2X                   | ~90%


-- =============================================================================
-- 3. IDLE TIME BY VARIANT
-- =============================================================================
-- CONTEXT: Idle time = how long a driver sits between finishing one trip
-- and accepting the next one. Shorter idle time = more earning time, less
-- frustration. If MRB is working, drivers in the preferred zone should pick up
-- the next ride faster because relevant offers come sooner.
-- NOTE: Exact idle time numbers here are hypothetical — directionally real.
-- =============================================================================

SELECT
    ea.variant,
    d.city,
    COUNT(DISTINCT e.driver_id)                              AS drivers, 
        ROUND(AVG(e.idle_seconds_before_accept) / 60.0, 2)         AS avg_idle_mins,   -- Average idle time before accepting a ride, in minutes
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
          (ORDER BY e.idle_seconds_before_accept) / 60.0, 2)       AS median_idle_mins   -- Median idle time (less affected by outliers than average)

FROM driver_events e
JOIN experiment_assignments ea
    ON e.driver_id = ea.driver_id
    AND ea.experiment_id = 'my_route_booking_v1'
JOIN drivers d USING (driver_id)

WHERE d.city IN ('Delhi', 'Jaipur')
  AND e.event_type = 'ride_accepted'   -- Only look at accepted rides — those are the events that have an idle_seconds_before_accept value to measure.
  AND e.event_time BETWEEN '2024-10-01' AND '2024-10-21'

GROUP BY 1, 2
ORDER BY city, variant;


-- =============================================================================
-- 4. TREATMENT EFFECT: MRB users vs non-users within the treatment arm
-- =============================================================================
-- CONTEXT: Being assigned to the treatment group ≠ using MRB.
-- Some treatment drivers may have never turned the feature on.
-- This query splits treatment into:
--   (a) "MRB on"  — drivers who actually used the feature
--   (b) "MRB off" — treatment drivers who didn't engage with it
-- If the lift concentrates in "MRB on", that's strong signal the feature
-- itself is driving the result, not just some selection bias.
-- =============================================================================

SELECT
    -- Three-way segment: control / treatment+MRB on / treatment+MRB off
    CASE
        WHEN ea.variant = 'control'              THEN 'control'
        WHEN ea.feature_enabled = true           THEN 'treatment — MRB on'
        ELSE                                          'treatment — MRB off'
    END                                                             AS segment,

    d.city,
    COUNT(DISTINCT e.driver_id)                                     AS drivers,
    ROUND(SUM(pings) / NULLIF(SUM(hours_online), 0), 2)            AS pings_per_hour,
    ROUND(100.0 * SUM(accepted) / NULLIF(SUM(pings), 0), 2)        AS acceptance_rate_pct

FROM (
    SELECT
        driver_id,
        DATE(event_time)                                            AS dt,
        SUM(online_duration_seconds) / 3600.0                      AS hours_online,
        COUNT(CASE WHEN event_type = 'ping_received' THEN 1 END)   AS pings,
        COUNT(CASE WHEN event_type = 'ride_accepted' THEN 1 END)   AS accepted
    FROM driver_events
    WHERE event_time BETWEEN '2024-10-01' AND '2024-10-21'
    GROUP BY 1, 2
) e

JOIN experiment_assignments ea USING (driver_id)
JOIN drivers d USING (driver_id)

WHERE ea.experiment_id = 'my_route_booking_v1'
  AND d.city IN ('Delhi', 'Jaipur')

GROUP BY 1, 2
ORDER BY city, segment;


-- =============================================================================
-- 5. GUARDRAIL: Did treatment cannibalise pings for non-MRB drivers?
-- =============================================================================
-- CONTEXT: Every ping sent to an MRB driver is a ping NOT sent to someone
-- else. If the algorithm is heavily favouring MRB users, non-MRB drivers in
-- the treatment group might be getting fewer offers than control drivers.
-- That would be a real harm — we're making some drivers worse off.
-- This query checks the "ping delta" for non-MRB drivers: treatment vs control.
-- Expectation: delta should be close to 0. A big negative = cannibalisation problem.
-- =============================================================================

WITH base AS (
    SELECT
        ea.variant,

        -- Label each driver as MRB-on or MRB-off
        CASE WHEN ea.feature_enabled = true THEN 'mrb_on' ELSE 'mrb_off' END AS mrb_status,

        d.city,

        -- Ping rate for each driver group
        SUM(CASE WHEN e.event_type = 'ping_received' THEN 1 ELSE 0 END)
            / NULLIF(SUM(e.online_duration_seconds) / 3600.0, 0)              AS pings_per_hour

    FROM driver_events e
    JOIN experiment_assignments ea USING (driver_id)
    JOIN drivers d USING (driver_id)
    WHERE ea.experiment_id = 'my_route_booking_v1'
      AND d.city IN ('Delhi', 'Jaipur')
      AND e.event_time BETWEEN '2024-10-01' AND '2024-10-21'
    GROUP BY 1, 2, 3
)

SELECT
    city,

    -- Ping rate for control-arm drivers (our baseline)
    -- NOTE: MAX() here is just a pivot trick — there's only one value per city
    --          for this combination, so MAX simply surfaces it.
    MAX(CASE WHEN variant = 'control'   AND mrb_status = 'mrb_off'
             THEN pings_per_hour END)                               AS ctrl_pings_per_hour,

    -- Ping rate for treatment drivers who did NOT use MRB
    MAX(CASE WHEN variant = 'treatment' AND mrb_status = 'mrb_off'
             THEN pings_per_hour END)                               AS trt_nonuser_pings_per_hour,

    -- % change in ping rate for non-MRB treatment drivers vs control
    -- NOTE: Formula = (treatment - control) / control × 100.
    --          A value near 0% = no cannibalisation.
    --          A strongly negative value (e.g. -20%) = red flag.
    ROUND(
        100.0 * (
            MAX(CASE WHEN variant = 'treatment' AND mrb_status = 'mrb_off'
                     THEN pings_per_hour END)
            - MAX(CASE WHEN variant = 'control' AND mrb_status = 'mrb_off'
                       THEN pings_per_hour END)
        ) / NULLIF(MAX(CASE WHEN variant = 'control' AND mrb_status = 'mrb_off'
                            THEN pings_per_hour END), 0),
    2)                                                              AS non_user_ping_delta_pct
    -- Expect: close to 0. A large negative number = cannibalisation.

FROM base
GROUP BY 1;


-- =============================================================================
-- 6. SHIFT-TIME BREAKDOWN — when are drivers using MRB?
-- =============================================================================
-- CONTEXT: MRB makes most intuitive sense at the START or END of a shift —
-- a driver heading out wants rides toward a busy zone; a driver heading home
-- wants rides toward their neighbourhood. The afternoon lull is another likely
-- window (drivers trying to reposition). This query tests that hypothesis by
-- showing what % of treatment drivers had MRB active in each time window.
-- If usage spikes at shift edges but not midday, that validates the use case.
-- =============================================================================

SELECT
    -- Bucket event timestamps into four meaningful time windows
    CASE
        WHEN EXTRACT(HOUR FROM e.event_time) BETWEEN 6  AND 10 THEN 'morning (6–10)'
        WHEN EXTRACT(HOUR FROM e.event_time) BETWEEN 11 AND 14 THEN 'afternoon lull (11–14)'
        WHEN EXTRACT(HOUR FROM e.event_time) BETWEEN 17 AND 21 THEN 'evening peak (17–21)'
        ELSE 'other'
    END                                                             AS time_window,

    d.city,

    -- How many treatment drivers had MRB active during this window?
    COUNT(DISTINCT CASE WHEN ea.feature_enabled = true
                        THEN e.driver_id END)                      AS mrb_active_drivers,

    -- MRB-active drivers as a % of ALL treatment drivers in this window
    -- NOTE: This normalises for the fact that more drivers are online
    --          during the evening peak than the morning window.
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN ea.feature_enabled = true
                                      THEN e.driver_id END)
          / NULLIF(COUNT(DISTINCT e.driver_id), 0), 2)             AS mrb_active_share_pct

FROM driver_events e

JOIN experiment_assignments ea
    ON e.driver_id = ea.driver_id
    AND ea.experiment_id = 'my_route_booking_v1'

    -- Only treatment arm — control had no access to MRB
    AND ea.variant = 'treatment'

JOIN drivers d USING (driver_id)

WHERE d.city IN ('Delhi', 'Jaipur')
  AND e.event_time BETWEEN '2024-10-01' AND '2024-10-21'

GROUP BY 1, 2
ORDER BY city, time_window;
