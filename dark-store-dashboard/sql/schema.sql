-- =============================================================
-- Dark Store Slot-Utilisation Dashboard — SQL Schema
-- Pin Code: 560068 (Koramangala, Bengaluru)
-- Operator: SwiftMart Dark Store (Zepto/Blinkit-style q-commerce)
-- =============================================================

-- ----------------------------------------------------------------
-- 1. REFERENCE TABLES
-- ----------------------------------------------------------------

CREATE TABLE dark_stores (
    store_id        SERIAL PRIMARY KEY,
    store_name      TEXT        NOT NULL,
    pin_code        CHAR(6)     NOT NULL DEFAULT '560068',
    city            TEXT        NOT NULL DEFAULT 'Bengaluru',
    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),
    total_picker_slots  INT     NOT NULL,  -- max concurrent active pickers
    operating_hours_start TIME  NOT NULL DEFAULT '06:00',
    operating_hours_end   TIME  NOT NULL DEFAULT '02:00',
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sku_categories (
    category_id     SERIAL PRIMARY KEY,
    category_name   TEXT NOT NULL,          -- e.g. 'Fruits & Vegetables', 'Dairy', 'Snacks'
    avg_pick_time_sec INT NOT NULL DEFAULT 45,  -- avg seconds to pick 1 unit
    cold_chain      BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE skus (
    sku_id          SERIAL PRIMARY KEY,
    sku_code        TEXT        NOT NULL UNIQUE,
    sku_name        TEXT        NOT NULL,
    category_id     INT         REFERENCES sku_categories(category_id),
    unit_price      NUMERIC(10,2) NOT NULL,
    shelf_life_days INT,
    reorder_point   INT         NOT NULL DEFAULT 20,   -- units — manual threshold (control)
    ml_reorder_point INT,                              -- ML-driven threshold (treatment)
    weight_grams    INT,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE inventory_snapshots (
    snapshot_id     BIGSERIAL PRIMARY KEY,
    store_id        INT         REFERENCES dark_stores(store_id),
    sku_id          INT         REFERENCES skus(sku_id),
    snapshot_time   TIMESTAMPTZ NOT NULL,
    stock_on_hand   INT         NOT NULL,
    reserved_stock  INT         NOT NULL DEFAULT 0,   -- allocated to in-flight orders
    available_stock INT GENERATED ALWAYS AS (stock_on_hand - reserved_stock) STORED
);

CREATE INDEX idx_inv_snapshot_time ON inventory_snapshots(store_id, snapshot_time);

-- ----------------------------------------------------------------
-- 2. PICKER SLOT CAPACITY (template per DOW × hour)
-- ----------------------------------------------------------------

CREATE TABLE slot_capacity_templates (
    template_id     SERIAL PRIMARY KEY,
    store_id        INT         REFERENCES dark_stores(store_id),
    day_of_week     SMALLINT    NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=Sun
    hour_of_day     SMALLINT    NOT NULL CHECK (hour_of_day BETWEEN 0 AND 23),
    planned_pickers INT         NOT NULL,   -- pickers scheduled
    max_orders_per_hour INT     NOT NULL,   -- theoretical throughput
    UNIQUE (store_id, day_of_week, hour_of_day)
);

-- ----------------------------------------------------------------
-- 3. ORDER + PICKING FACTS
-- ----------------------------------------------------------------

CREATE TABLE orders (
    order_id        BIGSERIAL PRIMARY KEY,
    store_id        INT         REFERENCES dark_stores(store_id),
    customer_id     BIGINT      NOT NULL,
    order_placed_at TIMESTAMPTZ NOT NULL,
    order_confirmed_at TIMESTAMPTZ,
    picking_started_at TIMESTAMPTZ,
    picking_completed_at TIMESTAMPTZ,
    dispatched_at   TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ,
    order_status    TEXT        NOT NULL CHECK (order_status IN (
                        'placed','confirmed','picking','packed','dispatched','delivered','cancelled'
                    )),
    delivery_pin    CHAR(6),
    gmv             NUMERIC(10,2),
    item_count      INT
);

CREATE INDEX idx_orders_store_placed ON orders(store_id, order_placed_at);
CREATE INDEX idx_orders_status       ON orders(order_status);

CREATE TABLE order_items (
    item_id         BIGSERIAL PRIMARY KEY,
    order_id        BIGINT      REFERENCES orders(order_id),
    sku_id          INT         REFERENCES skus(sku_id),
    quantity        INT         NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL,
    picked_quantity INT,                    -- may differ (substitution / OOS)
    pick_time_sec   INT                     -- actual seconds taken
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_sku   ON order_items(sku_id);

CREATE TABLE picker_sessions (
    session_id      BIGSERIAL PRIMARY KEY,
    store_id        INT         REFERENCES dark_stores(store_id),
    picker_id       INT         NOT NULL,
    session_date    DATE        NOT NULL,
    shift_start     TIMESTAMPTZ NOT NULL,
    shift_end       TIMESTAMPTZ NOT NULL,
    -- derived from order assignments
    active_pick_seconds  INT    DEFAULT 0,
    idle_seconds         INT    DEFAULT 0
);

CREATE TABLE picker_order_assignments (
    assignment_id   BIGSERIAL PRIMARY KEY,
    session_id      BIGINT      REFERENCES picker_sessions(session_id),
    order_id        BIGINT      REFERENCES orders(order_id),
    assigned_at     TIMESTAMPTZ NOT NULL,
    pick_start      TIMESTAMPTZ,
    pick_end        TIMESTAMPTZ,
    UNIQUE (order_id)   -- one picker per order
);

-- ----------------------------------------------------------------
-- 4. AGGREGATED SLOT UTILISATION FACT (materialised daily)
-- ----------------------------------------------------------------

CREATE TABLE slot_utilisation_hourly (
    util_id         BIGSERIAL PRIMARY KEY,
    store_id        INT         REFERENCES dark_stores(store_id),
    slot_date       DATE        NOT NULL,
    day_of_week     SMALLINT    NOT NULL,
    hour_of_day     SMALLINT    NOT NULL,
    planned_pickers INT         NOT NULL,
    active_pickers  INT         NOT NULL,  -- actually picking during ≥1 min of hour
    orders_picked   INT         NOT NULL,
    avg_pick_time_sec NUMERIC(8,2),
    idle_slot_minutes INT       NOT NULL,  -- sum of picker idle minutes in hour
    total_slot_minutes INT      NOT NULL,  -- planned_pickers * 60
    fill_rate       NUMERIC(5,4) GENERATED ALWAYS AS
                        (CASE WHEN total_slot_minutes = 0 THEN 0
                         ELSE 1.0 - (idle_slot_minutes::NUMERIC / total_slot_minutes)
                         END) STORED,
    UNIQUE (store_id, slot_date, hour_of_day)
);

-- ----------------------------------------------------------------
-- 5. STOCKOUT LOG (for success metric tracking)
-- ----------------------------------------------------------------

CREATE TABLE stockout_events (
    event_id        BIGSERIAL PRIMARY KEY,
    store_id        INT         REFERENCES dark_stores(store_id),
    sku_id          INT         REFERENCES skus(sku_id),
    detected_at     TIMESTAMPTZ NOT NULL,
    resolved_at     TIMESTAMPTZ,
    stockout_duration_min INT GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (resolved_at - detected_at))::INT / 60
    ) STORED,
    lost_order_count INT        DEFAULT 0,
    restock_trigger TEXT        CHECK (restock_trigger IN ('manual','ml_model','scheduled'))
);

-- ----------------------------------------------------------------
-- 6. A/B EXPERIMENT TRACKING
-- ----------------------------------------------------------------

CREATE TABLE ab_experiments (
    experiment_id   SERIAL PRIMARY KEY,
    experiment_name TEXT NOT NULL,
    hypothesis      TEXT,
    start_date      DATE NOT NULL,
    end_date        DATE,
    status          TEXT CHECK (status IN ('draft','running','paused','concluded'))
);

CREATE TABLE ab_store_assignments (
    store_id        INT  REFERENCES dark_stores(store_id),
    experiment_id   INT  REFERENCES ab_experiments(experiment_id),
    variant         TEXT NOT NULL CHECK (variant IN ('control','treatment')),
    assigned_at     TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (store_id, experiment_id)
);
