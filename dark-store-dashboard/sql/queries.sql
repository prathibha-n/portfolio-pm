-- =============================================================
-- Dark Store Analytics Queries — Pin Code 560068, Bengaluru
-- Sections:
--   Q1  Seed simulated data
--   Q2  Slot occupancy by hour-of-day × day-of-week
--   Q3  Idle time heatmap
--   Q4  Fill-rate by SKU category
--   Q5  Underutilised slot alert view
--   Q6  7-day rolling demand trend (feed for Python forecast)
--   Q7  A/B experiment interim metrics
-- =============================================================

-- ----------------------------------------------------------------
-- Q1: SEED REFERENCE DATA (run once)
-- ----------------------------------------------------------------

INSERT INTO dark_stores (store_name, pin_code, city, latitude, longitude,
                         total_picker_slots, operating_hours_start, operating_hours_end)
VALUES ('SwiftMart Koramangala', '560068', 'Bengaluru',
        12.9352, 77.6245, 12, '06:00', '02:00');

INSERT INTO sku_categories (category_name, avg_pick_time_sec, cold_chain) VALUES
  ('Fruits & Vegetables',  35, FALSE),
  ('Dairy & Eggs',         30, TRUE),
  ('Snacks & Beverages',   25, FALSE),
  ('Staples & Grains',     40, FALSE),
  ('Personal Care',        20, FALSE),
  ('Frozen Foods',         50, TRUE),
  ('Bakery',               30, FALSE),
  ('Cleaning Supplies',    25, FALSE);

-- Slot capacity template: weekday vs weekend, peak vs off-peak
INSERT INTO slot_capacity_templates (store_id, day_of_week, hour_of_day, planned_pickers, max_orders_per_hour)
SELECT
    1 AS store_id,
    dow,
    hr,
    CASE
        -- Off-peak night hours
        WHEN hr BETWEEN 2 AND 6   THEN 2
        -- Morning ramp-up
        WHEN hr BETWEEN 7 AND 9   THEN 6
        -- Lunch peak (higher on weekends)
        WHEN hr BETWEEN 12 AND 14 AND dow IN (0,6) THEN 12
        WHEN hr BETWEEN 12 AND 14 THEN 9
        -- Evening peak
        WHEN hr BETWEEN 18 AND 21 AND dow IN (0,6) THEN 12
        WHEN hr BETWEEN 18 AND 21 THEN 10
        -- Regular daytime
        ELSE 7
    END AS planned_pickers,
    CASE
        WHEN hr BETWEEN 2 AND 6   THEN 30
        WHEN hr BETWEEN 7 AND 9   THEN 90
        WHEN hr BETWEEN 12 AND 14 THEN 140
        WHEN hr BETWEEN 18 AND 21 THEN 150
        ELSE 100
    END AS max_orders_per_hour
FROM generate_series(0, 6) AS dow
CROSS JOIN generate_series(0, 23) AS hr;


-- ----------------------------------------------------------------
-- Q2: SLOT OCCUPANCY — by hour-of-day and day-of-week
--     Shows avg fill_rate across last 30 days
-- ----------------------------------------------------------------

SELECT
    suh.day_of_week,
    TO_CHAR(
        DATE '2024-01-07' + suh.day_of_week,   -- anchor to a known Sunday
        'Dy'
    )                           AS dow_label,
    suh.hour_of_day,
    suh.hour_of_day || ':00'    AS hour_label,
    ROUND(AVG(suh.fill_rate) * 100, 1)  AS avg_fill_rate_pct,
    ROUND(AVG(suh.active_pickers), 1)   AS avg_active_pickers,
    AVG(suh.planned_pickers)            AS avg_planned_pickers,
    SUM(suh.orders_picked)              AS total_orders,
    SUM(suh.idle_slot_minutes)          AS total_idle_minutes
FROM slot_utilisation_hourly suh
WHERE suh.store_id = 1
  AND suh.slot_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY suh.day_of_week, suh.hour_of_day
ORDER BY suh.day_of_week, suh.hour_of_day;


-- ----------------------------------------------------------------
-- Q3: IDLE TIME HEATMAP — worst 20 hour-of-day × DOW buckets
-- ----------------------------------------------------------------

WITH base AS (
    SELECT
        day_of_week,
        hour_of_day,
        AVG(idle_slot_minutes)              AS avg_idle_min,
        AVG(total_slot_minutes)             AS avg_total_min,
        ROUND(AVG(fill_rate) * 100, 2)      AS avg_fill_pct,
        COUNT(*)                            AS sample_days
    FROM slot_utilisation_hourly
    WHERE store_id = 1
      AND slot_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY day_of_week, hour_of_day
)
SELECT
    day_of_week,
    hour_of_day,
    ROUND(avg_idle_min, 1)      AS avg_idle_minutes,
    ROUND(avg_total_min, 1)     AS avg_total_slot_minutes,
    avg_fill_pct,
    sample_days,
    -- Bucket idle severity
    CASE
        WHEN avg_fill_pct >= 75 THEN 'Healthy'
        WHEN avg_fill_pct >= 50 THEN 'Moderate'
        WHEN avg_fill_pct >= 25 THEN 'Underutilised'
        ELSE                         'Critical-Idle'
    END                         AS utilisation_band
FROM base
ORDER BY avg_idle_min DESC
LIMIT 20;


-- ----------------------------------------------------------------
-- Q4: FILL-RATE BY SKU CATEGORY
--     Joins item picks back to categories for granular analysis
-- ----------------------------------------------------------------

SELECT
    sc.category_name,
    COUNT(DISTINCT oi.order_id)             AS orders_containing_category,
    SUM(oi.quantity)                        AS units_demanded,
    SUM(oi.picked_quantity)                 AS units_fulfilled,
    ROUND(
        100.0 * SUM(oi.picked_quantity)
              / NULLIF(SUM(oi.quantity), 0),
        2
    )                                       AS category_fill_rate_pct,
    ROUND(AVG(oi.pick_time_sec), 1)         AS avg_pick_time_sec,
    COUNT(*) FILTER (WHERE oi.picked_quantity < oi.quantity)
                                            AS partial_fills,
    COUNT(*) FILTER (WHERE oi.picked_quantity = 0)
                                            AS zero_fills            -- stockouts
FROM order_items oi
JOIN orders      o   ON o.order_id    = oi.order_id
JOIN skus        s   ON s.sku_id      = oi.sku_id
JOIN sku_categories sc ON sc.category_id = s.category_id
WHERE o.store_id = 1
  AND o.order_placed_at >= CURRENT_DATE - INTERVAL '30 days'
  AND o.order_status    != 'cancelled'
GROUP BY sc.category_name
ORDER BY category_fill_rate_pct ASC;   -- worst fill-rate first


-- ----------------------------------------------------------------
-- Q5: UNDERUTILISED SLOT ALERT VIEW
--     Flags upcoming hours (next 24h) predicted to be idle
--     Uses historical avg as a naive baseline
-- ----------------------------------------------------------------

CREATE OR REPLACE VIEW v_underutil_slot_alerts AS
WITH historical_avg AS (
    SELECT
        day_of_week,
        hour_of_day,
        AVG(fill_rate)      AS hist_avg_fill_rate,
        STDDEV(fill_rate)   AS hist_std_fill_rate
    FROM slot_utilisation_hourly
    WHERE store_id = 1
      AND slot_date >= CURRENT_DATE - INTERVAL '60 days'
    GROUP BY day_of_week, hour_of_day
),
upcoming_slots AS (
    SELECT
        gs                                              AS slot_start,
        EXTRACT(DOW FROM gs)::SMALLINT                 AS day_of_week,
        EXTRACT(HOUR FROM gs)::SMALLINT                AS hour_of_day
    FROM generate_series(
        DATE_TRUNC('hour', NOW()),
        DATE_TRUNC('hour', NOW()) + INTERVAL '24 hours',
        INTERVAL '1 hour'
    ) gs
)
SELECT
    us.slot_start,
    us.day_of_week,
    us.hour_of_day,
    sct.planned_pickers,
    ROUND(ha.hist_avg_fill_rate * 100, 1)   AS predicted_fill_rate_pct,
    ROUND(ha.hist_std_fill_rate * 100, 1)   AS fill_rate_std_pct,
    CASE
        WHEN ha.hist_avg_fill_rate < 0.40 THEN 'HIGH-RISK'
        WHEN ha.hist_avg_fill_rate < 0.60 THEN 'MODERATE-RISK'
        ELSE 'OK'
    END                                     AS alert_level,
    -- Suggested action: reduce planned pickers to save labour cost
    GREATEST(
        2,
        CEIL(sct.planned_pickers * ha.hist_avg_fill_rate)
    )::INT                                  AS recommended_pickers
FROM upcoming_slots us
JOIN historical_avg      ha  ON ha.day_of_week = us.day_of_week
                             AND ha.hour_of_day = us.hour_of_day
JOIN slot_capacity_templates sct ON sct.store_id = 1
                             AND sct.day_of_week = us.day_of_week
                             AND sct.hour_of_day = us.hour_of_day
ORDER BY us.slot_start;


-- ----------------------------------------------------------------
-- Q6: 7-DAY ROLLING DEMAND (export for Python ARIMA / Prophet)
-- ----------------------------------------------------------------

SELECT
    DATE_TRUNC('hour', o.order_placed_at)   AS order_hour,
    COUNT(*)                                AS order_count,
    SUM(o.item_count)                       AS total_items,
    SUM(o.gmv)                              AS total_gmv,
    AVG(EXTRACT(EPOCH FROM
        (o.picking_completed_at - o.picking_started_at))
    )                                       AS avg_pick_duration_sec,
    -- Feature columns for regressor
    EXTRACT(DOW  FROM o.order_placed_at)::INT  AS day_of_week,
    EXTRACT(HOUR FROM o.order_placed_at)::INT  AS hour_of_day,
    EXTRACT(DOY  FROM o.order_placed_at)::INT  AS day_of_year
FROM orders o
WHERE o.store_id = 1
  AND o.order_placed_at >= CURRENT_DATE - INTERVAL '90 days'
  AND o.order_status != 'cancelled'
GROUP BY DATE_TRUNC('hour', o.order_placed_at)
ORDER BY order_hour;


-- ----------------------------------------------------------------
-- Q7: A/B EXPERIMENT INTERIM METRICS
--     Treatment = ML restocking trigger | Control = manual threshold
-- ----------------------------------------------------------------

WITH experiment_stores AS (
    SELECT asa.store_id, asa.variant
    FROM ab_store_assignments asa
    WHERE asa.experiment_id = 1   -- ML Restocking Trigger v1
),
stockout_metrics AS (
    SELECT
        es.variant,
        COUNT(se.event_id)                      AS stockout_events,
        ROUND(AVG(se.stockout_duration_min), 1) AS avg_stockout_min,
        SUM(se.lost_order_count)                AS lost_orders
    FROM stockout_events se
    JOIN experiment_stores es ON es.store_id = se.store_id
    WHERE se.detected_at >= (SELECT start_date FROM ab_experiments WHERE experiment_id = 1)
    GROUP BY es.variant
),
utilisation_metrics AS (
    SELECT
        es.variant,
        ROUND(AVG(suh.fill_rate) * 100, 2)     AS avg_fill_rate_pct,
        SUM(suh.idle_slot_minutes)              AS total_idle_minutes,
        SUM(suh.orders_picked)                 AS total_orders_picked
    FROM slot_utilisation_hourly suh
    JOIN experiment_stores es ON es.store_id = suh.store_id
    WHERE suh.slot_date >= (SELECT start_date FROM ab_experiments WHERE experiment_id = 1)
    GROUP BY es.variant
)
SELECT
    um.variant,
    um.avg_fill_rate_pct,
    um.total_idle_minutes,
    um.total_orders_picked,
    sm.stockout_events,
    sm.avg_stockout_min,
    sm.lost_orders,
    -- Primary metric: fill_rate lift over control
    um.avg_fill_rate_pct
        - FIRST_VALUE(um.avg_fill_rate_pct) OVER (ORDER BY um.variant DESC)
                                                AS fill_rate_lift_pp
FROM utilisation_metrics um
JOIN stockout_metrics sm USING (variant)
ORDER BY um.variant;
