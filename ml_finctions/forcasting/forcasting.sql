-- ============================================================
--  STEP 1 — Create Database, Schema & Load Demo Data
--  Snowflake ML Forecasting — Restaurant Demo
-- ============================================================

-- Create database and set context
CREATE DATABASE IF NOT EXISTS RESTO_DB;
USE DATABASE RESTO_DB;
USE SCHEMA PUBLIC;

-- ── Create tables ────────────────────────────────────────────

CREATE OR REPLACE TABLE RESTO_DB.PUBLIC.RESTAURANT_ORDERS (
  outlet_id     VARCHAR,        -- outlet identifier
  outlet_name   VARCHAR,        -- human-readable name
  order_date    TIMESTAMP_NTZ,  -- daily timestamp
  orders        FLOAT,          -- target: number of orders
  temperature   NUMBER,         -- °C that day
  rainfall_mm   FLOAT,          -- rainfall in mm
  is_weekend    BOOLEAN,        -- Sat/Sun = TRUE
  promotion     VARCHAR         -- active promo, NULL if none
);

INSERT INTO RESTO_DB.PUBLIC.RESTAURANT_ORDERS VALUES
-- ── Outlet A: The Spice Garden (high-traffic, city centre) ──
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-01'), 312, 18, 0.0, FALSE, 'new_year'),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-02'), 278, 19, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-03'), 265, 17, 2.1, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-04'), 271, 16, 5.4, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-05'), 295, 18, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-06'), 340, 20, 0.0, TRUE,  'weekend_special'),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-07'), 358, 21, 0.0, TRUE,  'weekend_special'),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-08'), 260, 17, 3.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-09'), 248, 16, 6.2, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-10'), 255, 17, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-11'), 263, 18, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-12'), 270, 19, 1.1, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-13'), 335, 22, 0.0, TRUE,  NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-14'), 349, 23, 0.0, TRUE,  NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-15'), 261, 19, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-16'), 252, 18, 4.5, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-17'), 258, 17, 7.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-18'), 267, 18, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-19'), 274, 20, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-20'), 342, 24, 0.0, TRUE,  'happy_hour'),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-21'), 361, 25, 0.0, TRUE,  'happy_hour'),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-22'), 268, 21, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-23'), 255, 20, 2.3, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-24'), 262, 19, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-25'), 270, 18, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-26'), 278, 19, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-27'), 338, 22, 0.0, TRUE,  NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-28'), 352, 23, 0.0, TRUE,  NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-29'), 264, 20, 1.5, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-30'), 257, 19, 3.8, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-01-31'), 265, 18, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-02-01'), 272, 19, 0.0, FALSE, NULL),
('A', 'The Spice Garden', TO_TIMESTAMP_NTZ('2024-02-02'), 280, 20, 0.0, FALSE, NULL),

-- ── Outlet B: Coastal Bites (mid-traffic, suburb) ──────────
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-01'), 187, 18, 0.0, FALSE, 'new_year'),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-02'), 162, 19, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-03'), 154, 17, 2.1, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-04'), 159, 16, 5.4, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-05'), 168, 18, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-06'), 214, 20, 0.0, TRUE,  'weekend_special'),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-07'), 228, 21, 0.0, TRUE,  'weekend_special'),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-08'), 151, 17, 3.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-09'), 144, 16, 6.2, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-10'), 149, 17, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-11'), 155, 18, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-12'), 161, 19, 1.1, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-13'), 209, 22, 0.0, TRUE,  NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-14'), 221, 23, 0.0, TRUE,  NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-15'), 152, 19, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-16'), 146, 18, 4.5, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-17'), 150, 17, 7.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-18'), 157, 18, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-19'), 163, 20, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-20'), 218, 24, 0.0, TRUE,  'happy_hour'),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-21'), 232, 25, 0.0, TRUE,  'happy_hour'),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-22'), 158, 21, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-23'), 149, 20, 2.3, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-24'), 154, 19, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-25'), 160, 18, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-26'), 166, 19, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-27'), 213, 22, 0.0, TRUE,  NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-28'), 226, 23, 0.0, TRUE,  NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-29'), 155, 20, 1.5, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-30'), 148, 19, 3.8, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-01-31'), 153, 18, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-02-01'), 160, 19, 0.0, FALSE, NULL),
('B', 'Coastal Bites', TO_TIMESTAMP_NTZ('2024-02-02'), 167, 20, 0.0, FALSE, NULL),

-- ── Outlet C: Urban Grille (low-traffic, airport kiosk) ────
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-01'), 95,  18, 0.0, FALSE, 'new_year'),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-02'), 88,  19, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-03'), 82,  17, 2.1, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-04'), 85,  16, 5.4, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-05'), 90,  18, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-06'), 104, 20, 0.0, TRUE,  'weekend_special'),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-07'), 112, 21, 0.0, TRUE,  'weekend_special'),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-08'), 80,  17, 3.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-09'), 76,  16, 6.2, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-10'), 79,  17, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-11'), 83,  18, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-12'), 86,  19, 1.1, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-13'), 108, 22, 0.0, TRUE,  NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-14'), 115, 23, 0.0, TRUE,  NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-15'), 81,  19, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-16'), 77,  18, 4.5, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-17'), 80,  17, 7.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-18'), 84,  18, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-19'), 88,  20, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-20'), 110, 24, 0.0, TRUE,  'happy_hour'),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-21'), 118, 25, 0.0, TRUE,  'happy_hour'),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-22'), 85,  21, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-23'), 80,  20, 2.3, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-24'), 83,  19, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-25'), 87,  18, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-26'), 91,  19, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-27'), 109, 22, 0.0, TRUE,  NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-28'), 116, 23, 0.0, TRUE,  NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-29'), 83,  20, 1.5, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-30'), 79,  19, 3.8, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-01-31'), 82,  18, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-02-01'), 86,  19, 0.0, FALSE, NULL),
('C', 'Urban Grille', TO_TIMESTAMP_NTZ('2024-02-02'), 90,  20, 0.0, FALSE, NULL);


-- ── Future features table ────────────────────────────────────

CREATE OR REPLACE TABLE RESTO_DB.PUBLIC.RESTAURANT_FUTURE_FEATURES (
  outlet_id   VARCHAR,
  order_date  TIMESTAMP_NTZ,
  temperature NUMBER,
  rainfall_mm FLOAT,
  is_weekend  BOOLEAN,
  promotion   VARCHAR
);

INSERT INTO RESTO_DB.PUBLIC.RESTAURANT_FUTURE_FEATURES VALUES
('A', TO_TIMESTAMP_NTZ('2024-02-03'), 21, 0.0, TRUE,  'valentines_week'),
('A', TO_TIMESTAMP_NTZ('2024-02-04'), 22, 0.0, TRUE,  'valentines_week'),
('A', TO_TIMESTAMP_NTZ('2024-02-05'), 20, 1.2, FALSE, NULL),
('A', TO_TIMESTAMP_NTZ('2024-02-06'), 19, 0.0, FALSE, NULL),
('A', TO_TIMESTAMP_NTZ('2024-02-07'), 18, 0.0, FALSE, NULL),
('B', TO_TIMESTAMP_NTZ('2024-02-03'), 21, 0.0, TRUE,  'valentines_week'),
('B', TO_TIMESTAMP_NTZ('2024-02-04'), 22, 0.0, TRUE,  'valentines_week'),
('B', TO_TIMESTAMP_NTZ('2024-02-05'), 20, 1.2, FALSE, NULL),
('B', TO_TIMESTAMP_NTZ('2024-02-06'), 19, 0.0, FALSE, NULL),
('B', TO_TIMESTAMP_NTZ('2024-02-07'), 18, 0.0, FALSE, NULL),
('C', TO_TIMESTAMP_NTZ('2024-02-03'), 21, 0.0, TRUE,  'valentines_week'),
('C', TO_TIMESTAMP_NTZ('2024-02-04'), 22, 0.0, TRUE,  'valentines_week'),
('C', TO_TIMESTAMP_NTZ('2024-02-05'), 20, 1.2, FALSE, NULL),
('C', TO_TIMESTAMP_NTZ('2024-02-06'), 19, 0.0, FALSE, NULL),
('C', TO_TIMESTAMP_NTZ('2024-02-07'), 18, 0.0, FALSE, NULL);

-- Verify
SELECT outlet_id, COUNT(*) AS rows FROM RESTO_DB.PUBLIC.RESTAURANT_ORDERS GROUP BY outlet_id ORDER BY outlet_id;

-- ============================================================
--  STEP 2 — Single Series Forecast
--  Forecast daily orders for Outlet A (The Spice Garden) only
-- ============================================================

USE DATABASE RESTO_DB;
USE SCHEMA PUBLIC;

-- ── Create a view for Outlet A ───────────────────────────────
CREATE OR REPLACE VIEW RESTO_DB.PUBLIC.V_OUTLET_A AS
  SELECT order_date, orders
  FROM RESTO_DB.PUBLIC.RESTAURANT_ORDERS
  WHERE outlet_id = 'A';

SELECT * FROM RESTO_DB.PUBLIC.V_OUTLET_A ORDER BY order_date;

-- ── Train the model ──────────────────────────────────────────
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST MODEL_OUTLET_A (
  INPUT_DATA        => TABLE(RESTO_DB.PUBLIC.V_OUTLET_A),
  TIMESTAMP_COLNAME => 'order_date',
  TARGET_COLNAME    => 'orders'
);

-- ── Forecast next 7 days ─────────────────────────────────────
-- Output: SERIES | TS | FORECAST | LOWER_BOUND | UPPER_BOUND
CALL MODEL_OUTLET_A!FORECAST(FORECASTING_PERIODS => 7);

-- ── Forecast with custom 80% prediction interval ─────────────
CALL MODEL_OUTLET_A!FORECAST(
  FORECASTING_PERIODS => 7,
  CONFIG_OBJECT => {'prediction_interval': 0.8}
);
