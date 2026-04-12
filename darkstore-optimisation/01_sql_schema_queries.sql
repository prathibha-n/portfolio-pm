-- ============================================================
-- DARK STORE SLOT UTILISATION DASHBOARD
-- Pin Code: 560068 (Bellandur, Bengaluru)
-- Store: Zepto-style dark store, ~3000 sq ft, 8 picker slots
-- ============================================================

-- ============================================================
-- SCHEMA
-- ============================================================

CREATE TABLE dim_store (
    store_id        SERIAL PRIMARY KEY,
    store_name      TEXT NOT NULL,
    pin_code        CHAR(6) NOT NULL DEFAULT '560068',
    city            TEXT NOT NULL DEFAULT 'Bengaluru',
    total_slots     INT NOT NULL,         -- physical picker stations
    operating_start TIME NOT NULL,        -- e.g. 06:00
    operating_end   TIME NOT NULL         -- e.g. 23:59
);

CREATE TABLE dim_sku (
    sku_id          SERIAL PRIMARY KEY,
    sku_name        TEXT NOT NULL,
    category        TEXT NOT NULL,        -- Grocery, Dairy, Snacks, Beverages, Personal Care, Frozen
    sub_category    TEXT,
    unit_price      NUMERIC(8,2),
    reorder_point   INT NOT NULL,         -- units threshold for restocking
    max_stock       INT NOT NULL
);

CREATE TABLE dim_picker (
    picker_id       SERIAL PRIMARY KEY,
    store_id        INT REFERENCES dim_store(store_id),
    slot_number     INT NOT NULL,         -- 1..N physical slots
    shift           TEXT NOT NULL         -- 'morning' | 'afternoon' | 'night'
);

CREATE TABLE fact_orders (
    order_id        BIGSERIAL PRIMARY KEY,
    store_id        INT REFERENCES dim_store(store_id),
    order_ts        TIMESTAMP NOT NULL,
    delivery_ts     TIMESTAMP,
    sku_id          INT REFERENCES dim_sku(sku_id),
    quantity        INT NOT NULL,
    order_status    TEXT NOT NULL,        -- placed | picked | dispatched | delivered | cancelled
    picker_id       INT REFERENCES dim_picker(picker_id)
);

CREATE TABLE fact_slot_activity (
    activity_id     BIGSERIAL PRIMARY KEY,
    picker_id       INT REFERENCES dim_picker(picker_id),
    slot_number     INT NOT NULL,
    activity_date   DATE NOT NULL,
    hour_of_day     INT NOT NULL CHECK (hour_of_day BETWEEN 0 AND 23),
    day_of_week     INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=Sun
    slot_capacity   INT NOT NULL,         -- max orders this slot can handle per hour
    orders_handled  INT NOT NULL DEFAULT 0,
    idle_minutes    INT NOT NULL DEFAULT 0,
    active_minutes  INT NOT NULL DEFAULT 0
);

CREATE TABLE fact_inventory_snapshot (
    snapshot_id     BIGSERIAL PRIMARY KEY,
    store_id        INT REFERENCES dim_store(store_id),
    sku_id          INT REFERENCES dim_sku(sku_id),
    snapshot_ts     TIMESTAMP NOT NULL,
    stock_on_hand   INT NOT NULL,
    stockout_flag   BOOLEAN NOT NULL DEFAULT FALSE
);

-- Indexes for dashboard query performance
CREATE INDEX idx_slot_date_hour   ON fact_slot_activity(activity_date, hour_of_day);
CREATE INDEX idx_slot_dow         ON fact_slot_activity(day_of_week);
CREATE INDEX idx_orders_ts        ON fact_orders(order_ts);
CREATE INDEX idx_inventory_ts     ON fact_inventory_snapshot(snapshot_ts, sku_id);


-- ============================================================
-- QUERY 1: SLOT OCCUPANCY BY HOUR-OF-DAY
-- Shows average fill-rate per hour across all days
-- ============================================================

SELECT
    hour_of_day,
    SUM(orders_handled)                                          AS total_orders,
    SUM(slot_capacity)                                           AS total_capacity,
    ROUND(
        100.0 * SUM(orders_handled) / NULLIF(SUM(slot_capacity), 0),
        2
    )                                                            AS occupancy_pct,
    ROUND(AVG(idle_minutes), 1)                                  AS avg_idle_minutes,
    CASE
        WHEN 100.0 * SUM(orders_handled) / NULLIF(SUM(slot_capacity), 0) < 40
        THEN 'UNDERUTILISED'
        WHEN 100.0 * SUM(orders_handled) / NULLIF(SUM(slot_capacity), 0) > 85
        THEN 'OVERLOADED'
        ELSE 'OPTIMAL'
    END                                                          AS utilisation_band
FROM fact_slot_activity
WHERE activity_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- ============================================================
-- QUERY 2: SLOT OCCUPANCY BY DAY-OF-WEEK x HOUR (HEATMAP)
-- Pivot-ready for dashboard heatmap
-- ============================================================

SELECT
    day_of_week,
    CASE day_of_week
        WHEN 0 THEN 'Sun' WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue'
        WHEN 3 THEN 'Wed' WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri'
        WHEN 6 THEN 'Sat'
    END                                                          AS day_label,
    hour_of_day,
    ROUND(
        100.0 * SUM(orders_handled) / NULLIF(SUM(slot_capacity), 0),
        2
    )                                                            AS occupancy_pct,
    SUM(idle_minutes)                                            AS total_idle_minutes
FROM fact_slot_activity
WHERE activity_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY day_of_week, hour_of_day
ORDER BY day_of_week, hour_of_day;


-- ============================================================
-- QUERY 3: IDLE TIME REPORT — TOP UNDERUTILISED SLOTS
-- Identifies specific picker slots with chronic idle hours
-- ============================================================

SELECT
    p.slot_number,
    p.shift,
    sa.hour_of_day,
    sa.day_of_week,
    COUNT(*)                                                     AS observation_days,
    ROUND(AVG(sa.idle_minutes), 1)                               AS avg_idle_mins,
    ROUND(AVG(sa.active_minutes), 1)                             AS avg_active_mins,
    ROUND(
        100.0 * AVG(sa.orders_handled) / NULLIF(AVG(sa.slot_capacity), 0),
        2
    )                                                            AS avg_fill_rate_pct
FROM fact_slot_activity sa
JOIN dim_picker p ON sa.picker_id = p.picker_id
WHERE sa.activity_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.slot_number, p.shift, sa.hour_of_day, sa.day_of_week
HAVING AVG(sa.idle_minutes) > 30          -- flag slots idle >30 min/hr on average
ORDER BY avg_idle_mins DESC
LIMIT 20;


-- ============================================================
-- QUERY 4: FILL-RATE BY SKU CATEGORY
-- Links order volume to category demand patterns
-- ============================================================

SELECT
    sk.category,
    DATE_TRUNC('hour', o.order_ts)                               AS order_hour,
    COUNT(DISTINCT o.order_id)                                   AS order_count,
    SUM(o.quantity)                                              AS units_sold,
    ROUND(AVG(o.quantity), 2)                                    AS avg_basket_size,
    COUNT(DISTINCT o.picker_id)                                  AS pickers_used
FROM fact_orders o
JOIN dim_sku sk ON o.sku_id = sk.sku_id
WHERE o.order_ts >= CURRENT_DATE - INTERVAL '30 days'
  AND o.order_status NOT IN ('cancelled')
GROUP BY sk.category, DATE_TRUNC('hour', o.order_ts)
ORDER BY sk.category, order_hour;


-- ============================================================
-- QUERY 5: STOCKOUT RATE BY SKU CATEGORY (last 30 days)
-- ============================================================

SELECT
    sk.category,
    sk.sku_name,
    COUNT(*)                                                      AS total_snapshots,
    SUM(CASE WHEN inv.stockout_flag THEN 1 ELSE 0 END)            AS stockout_count,
    ROUND(
        100.0 * SUM(CASE WHEN inv.stockout_flag THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    )                                                             AS stockout_rate_pct
FROM fact_inventory_snapshot inv
JOIN dim_sku sk ON inv.sku_id = sk.sku_id
WHERE inv.snapshot_ts >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY sk.category, sk.sku_name
ORDER BY stockout_rate_pct DESC;


-- ============================================================
-- QUERY 6: DAILY SLOT UTILISATION SUMMARY (for time-series)
-- Feed this into the Python forecast model
-- ============================================================

SELECT
    activity_date,
    EXTRACT(DOW FROM activity_date)                               AS day_of_week,
    SUM(orders_handled)                                           AS daily_orders,
    SUM(slot_capacity)                                            AS daily_capacity,
    ROUND(
        100.0 * SUM(orders_handled) / NULLIF(SUM(slot_capacity), 0),
        2
    )                                                             AS daily_utilisation_pct,
    SUM(idle_minutes)                                             AS total_idle_minutes
FROM fact_slot_activity
GROUP BY activity_date
ORDER BY activity_date;


-- ============================================================
-- QUERY 7: PICKER EFFICIENCY LEADERBOARD
-- ============================================================

SELECT
    p.picker_id,
    p.slot_number,
    p.shift,
    COUNT(DISTINCT sa.activity_date)                              AS days_active,
    SUM(sa.orders_handled)                                        AS total_orders,
    ROUND(AVG(sa.orders_handled), 2)                              AS avg_orders_per_hour,
    ROUND(AVG(sa.idle_minutes), 1)                                AS avg_idle_mins,
    ROUND(
        100.0 * SUM(sa.active_minutes)
        / NULLIF(SUM(sa.active_minutes + sa.idle_minutes), 0),
        2
    )                                                             AS utilisation_pct
FROM fact_slot_activity sa
JOIN dim_picker p ON sa.picker_id = p.picker_id
WHERE sa.activity_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.picker_id, p.slot_number, p.shift
ORDER BY utilisation_pct DESC;
