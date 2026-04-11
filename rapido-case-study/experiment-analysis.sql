-- =============================================================================
-- Rapido: My Route Booking — Experiment Analysis
-- Feature: Preferred destination → increased attractiveness weight in allocation
-- Experiment: A/B test, Delhi and Jaipur
-- Primary metrics: ping rate, acceptance rate, idle time
-- =============================================================================
-- NOTE: Table/column names are illustrative — adapt to actual Rapido schema.
-- Outcome numbers (idle time, exact dates) are hypothetical scaffolding.
-- Ping 2× lift and 80% → 90% acceptance are real experiment results.
-- =============================================================================


-- =============================================================================
-- 1. FEATURE ADOPTION — who turned on My Route Booking?
-- =============================================================================

SELECT
    city,
    COUNT(DISTINCT driver_id)                                   AS total_drivers_in_experiment,
    COUNT(DISTINCT CASE WHEN feature_enabled = true
                        THEN driver_id END)                     AS mrb_users,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN feature_enabled = true
                                      THEN driver_id END)
          / COUNT(DISTINCT driver_id), 2)                       AS adoption_rate_pct
FROM experiment_assignments ea
JOIN drivers d USING (driver_id)
WHERE d.city IN ('Delhi', 'Jaipur')
  AND ea.variant = 'treatment'
  AND ea.experiment_id = 'my_route_booking_v1'
GROUP BY 1;


-- =============================================================================
-- 2. CORE RESULT: Ping rate and acceptance rate by variant
--    This is the primary readout — what actually moved.
-- =============================================================================

WITH driver_daily AS (
    SELECT
        ea.variant,
        e.driver_id,
        d.city,
        DATE(e.event_time)                                          AS event_date,
        SUM(online_duration_seconds) / 3600.0                       AS hours_online,
        COUNT(CASE WHEN e.event_type = 'ping_received' THEN 1 END)  AS pings_received,
        COUNT(CASE WHEN e.event_type = 'ride_accepted' THEN 1 END)  AS rides_accepted
    FROM driver_events e
    JOIN experiment_assignments ea
        ON e.driver_id = ea.driver_id
        AND ea.experiment_id = 'my_route_booking_v1'
    JOIN drivers d USING (driver_id)
    WHERE d.city IN ('Delhi', 'Jaipur')
      AND e.event_time BETWEEN '2024-10-01' AND '2024-10-21'
    GROUP BY 1, 2, 3, 4
)

SELECT
    variant,
    city,
    COUNT(DISTINCT driver_id)                                       AS drivers,
    -- Ping rate: rides offered per hour online
    ROUND(SUM(pings_received) / NULLIF(SUM(hours_online), 0), 2)   AS pings_per_hour_online,
    -- Acceptance rate
    ROUND(100.0 * SUM(rides_accepted)
          / NULLIF(SUM(pings_received), 0), 2)                     AS acceptance_rate_pct
FROM driver_daily
GROUP BY 1, 2
ORDER BY city, variant;

-- Expected output (real results):
-- variant    | city   | pings_per_hour_online | acceptance_rate_pct
-- control    | Delhi  | ~X                    | ~80%
-- treatment  | Delhi  | ~2X                   | ~90%
-- control    | Jaipur | ~X                    | ~80%
-- treatment  | Jaipur | ~2X                   | ~90%


-- =============================================================================
-- 3. IDLE TIME BY VARIANT (hypothetical numbers — directionally real)
-- =============================================================================

SELECT
    ea.variant,
    d.city,
    COUNT(DISTINCT e.driver_id)                                     AS drivers,
    -- Idle time: gap between trip completion and next accepted ping
    ROUND(AVG(e.idle_seconds_before_accept) / 60.0, 2)             AS avg_idle_mins,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
          (ORDER BY e.idle_seconds_before_accept) / 60.0, 2)       AS median_idle_mins
FROM driver_events e
JOIN experiment_assignments ea
    ON e.driver_id = ea.driver_id
    AND ea.experiment_id = 'my_route_booking_v1'
JOIN drivers d USING (driver_id)
WHERE d.city IN ('Delhi', 'Jaipur')
  AND e.event_type = 'ride_accepted'
  AND e.event_time BETWEEN '2024-10-01' AND '2024-10-21'
GROUP BY 1, 2
ORDER BY city, variant;


-- =============================================================================
-- 4. TREATMENT EFFECT: MRB users vs non-users within treatment arm
--    Isolates the feature effect from the variant assignment effect
-- =============================================================================

SELECT
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
--    Non-MRB drivers in treatment should not see a meaningful ping drop
-- =============================================================================

WITH base AS (
    SELECT
        ea.variant,
        CASE WHEN ea.feature_enabled = true THEN 'mrb_on' ELSE 'mrb_off' END AS mrb_status,
        d.city,
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
    MAX(CASE WHEN variant = 'control'   AND mrb_status = 'mrb_off'
             THEN pings_per_hour END)                               AS ctrl_pings_per_hour,
    MAX(CASE WHEN variant = 'treatment' AND mrb_status = 'mrb_off'
             THEN pings_per_hour END)                               AS trt_nonuser_pings_per_hour,
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
--    Hypothesis: usage clusters at start-of-shift, end-of-shift, afternoon lull
-- =============================================================================

SELECT
    CASE
        WHEN EXTRACT(HOUR FROM e.event_time) BETWEEN 6  AND 10 THEN 'morning (6–10)'
        WHEN EXTRACT(HOUR FROM e.event_time) BETWEEN 11 AND 14 THEN 'afternoon lull (11–14)'
        WHEN EXTRACT(HOUR FROM e.event_time) BETWEEN 17 AND 21 THEN 'evening peak (17–21)'
        ELSE 'other'
    END                                                             AS time_window,
    d.city,
    COUNT(DISTINCT CASE WHEN ea.feature_enabled = true
                        THEN e.driver_id END)                      AS mrb_active_drivers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN ea.feature_enabled = true
                                      THEN e.driver_id END)
          / NULLIF(COUNT(DISTINCT e.driver_id), 0), 2)             AS mrb_active_share_pct
FROM driver_events e
JOIN experiment_assignments ea
    ON e.driver_id = ea.driver_id
    AND ea.experiment_id = 'my_route_booking_v1'
    AND ea.variant = 'treatment'
JOIN drivers d USING (driver_id)
WHERE d.city IN ('Delhi', 'Jaipur')
  AND e.event_time BETWEEN '2024-10-01' AND '2024-10-21'
GROUP BY 1, 2
ORDER BY city, time_window;
