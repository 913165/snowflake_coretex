-- ============================================================
--  Snowflake ML Top Insights — HOTEL INDUSTRY DEMO (FIXED)
--  Question: Resort hotels have lower guest satisfaction scores
--            than City hotels. Which segments explain the gap?
-- ============================================================
--drop database HOTEL_INSIGHTS_DB
CREATE DATABASE IF NOT EXISTS HOTEL_INSIGHTS_DB;
USE DATABASE HOTEL_INSIGHTS_DB;
USE SCHEMA PUBLIC;

-- ============================================================
--  STEP 1 — Create & load bookings table
-- ============================================================

CREATE OR REPLACE TABLE HOTEL_INSIGHTS_DB.PUBLIC.BOOKINGS (
  booking_id           VARCHAR,
  hotel_type           VARCHAR,
  booking_channel      VARCHAR,
  room_type            VARCHAR,
  guest_type           VARCHAR,
  lead_time_days       NUMBER,
  length_of_stay       NUMBER,
  num_special_requests NUMBER,
  repeat_guest         BOOLEAN,
  season               VARCHAR,
  satisfaction_score   FLOAT
);

-- City hotel stays — HIGH satisfaction (control, label = FALSE)
INSERT INTO HOTEL_INSIGHTS_DB.PUBLIC.BOOKINGS
WITH city_base AS (
  SELECT
    'CITY-' || SEQ4()                                                  AS booking_id,
    'City'                                                             AS hotel_type,
    ['Direct','OTA','Corporate','Travel_Agent'][MOD(ABS(RANDOM()),4)]  AS booking_channel,
    ['Standard','Deluxe','Suite','Family'][MOD(ABS(RANDOM()),4)]       AS room_type,
    ['Solo','Couple','Family','Business'][MOD(ABS(RANDOM()),4)]        AS guest_type,
    UNIFORM(1, 300, RANDOM())                                          AS lead_time_days,
    UNIFORM(1, 14, RANDOM())                                           AS length_of_stay,
    UNIFORM(0, 8, RANDOM())                                            AS num_special_requests,
    (MOD(ABS(RANDOM()), 4) = 0)                                        AS repeat_guest,
    ['Peak','Shoulder','Off-Peak'][MOD(ABS(RANDOM()),3)]               AS season
  FROM TABLE(GENERATOR(ROWCOUNT=>650))
)
SELECT
  booking_id,
  hotel_type,
  booking_channel,
  room_type,
  guest_type,
  lead_time_days,
  length_of_stay,
  num_special_requests,
  repeat_guest,
  season,
  CASE
    -- Suite + Direct + Repeat = premium city experience
    WHEN room_type = 'Suite'
     AND booking_channel = 'Direct'
     AND repeat_guest = TRUE
    THEN UNIFORM(8.5, 10.0, RANDOM())

    -- Corporate bookings = consistently satisfied (managed expectations)
    WHEN booking_channel = 'Corporate'
    THEN UNIFORM(7.5, 9.5, RANDOM())

    -- Everyone else: generally high city scores
    ELSE UNIFORM(6.5, 9.0, RANDOM())
  END AS satisfaction_score
FROM city_base;


-- Resort hotel stays — LOWER satisfaction (test, label = TRUE)
INSERT INTO HOTEL_INSIGHTS_DB.PUBLIC.BOOKINGS
WITH resort_base AS (
  SELECT
    'RESORT-' || SEQ4()                                                AS booking_id,
    'Resort'                                                           AS hotel_type,
    ['Direct','OTA','Corporate','Travel_Agent'][MOD(ABS(RANDOM()),4)]  AS booking_channel,
    ['Standard','Deluxe','Suite','Family'][MOD(ABS(RANDOM()),4)]       AS room_type,
    ['Solo','Couple','Family','Business'][MOD(ABS(RANDOM()),4)]        AS guest_type,
    UNIFORM(1, 300, RANDOM())                                          AS lead_time_days,
    UNIFORM(1, 14, RANDOM())                                           AS length_of_stay,
    UNIFORM(0, 8, RANDOM())                                            AS num_special_requests,
    (MOD(ABS(RANDOM()), 4) = 0)                                        AS repeat_guest,
    ['Peak','Shoulder','Off-Peak'][MOD(ABS(RANDOM()),3)]               AS season
  FROM TABLE(GENERATOR(ROWCOUNT=>550))
)
SELECT
  booking_id,
  hotel_type,
  booking_channel,
  room_type,
  guest_type,
  lead_time_days,
  length_of_stay,
  num_special_requests,
  repeat_guest,
  season,
  CASE
    -- OTA + Peak = biggest disappointment (inflated expectations)
    WHEN booking_channel = 'OTA'
     AND season = 'Peak'
    THEN UNIFORM(3.5, 6.5, RANDOM())

    -- Family rooms in Peak = overcrowding, noise, low scores
    WHEN room_type = 'Family'
     AND season = 'Peak'
    THEN UNIFORM(4.0, 6.8, RANDOM())

    -- Business guests = least satisfied (wrong hotel type)
    WHEN guest_type = 'Business'
    THEN UNIFORM(3.0, 6.0, RANDOM())

    -- OTA + Off-Peak = moderate disappointment
    WHEN booking_channel = 'OTA'
     AND season = 'Off-Peak'
    THEN UNIFORM(4.5, 7.0, RANDOM())

    -- Repeat guests + Suite + Direct = bright spot, close to City
    WHEN repeat_guest = TRUE
     AND room_type = 'Suite'
     AND booking_channel = 'Direct'
    THEN UNIFORM(7.5, 9.8, RANDOM())

    -- Repeat guests (any) = above average resort experience
    WHEN repeat_guest = TRUE
    THEN UNIFORM(6.0, 8.5, RANDOM())

    -- Everyone else: moderate gap vs City
    ELSE UNIFORM(5.0, 7.5, RANDOM())
  END AS satisfaction_score
FROM resort_base;


-- Sanity check: City ~8.0 avg, Resort ~5.5-6.5 avg
SELECT
  hotel_type,
  COUNT(*)                           AS bookings,
  ROUND(AVG(satisfaction_score), 2)  AS avg_score,
  ROUND(MIN(satisfaction_score), 2)  AS min_score,
  ROUND(MAX(satisfaction_score), 2)  AS max_score
FROM HOTEL_INSIGHTS_DB.PUBLIC.BOOKINGS
GROUP BY hotel_type ORDER BY hotel_type;


-- ============================================================
--  STEP 2 — Labeled view
-- ============================================================

CREATE OR REPLACE VIEW HOTEL_INSIGHTS_DB.PUBLIC.V_BOOKINGS AS
  SELECT
    satisfaction_score,
    booking_channel,
    room_type,
    guest_type,
    season,
    CAST(repeat_guest AS VARCHAR)          AS repeat_guest,
    CAST(num_special_requests AS VARCHAR)  AS special_requests,
    -- Bucket lead time into categories instead of raw number
    CASE
      WHEN lead_time_days <= 30  THEN 'Short'
      WHEN lead_time_days <= 90  THEN 'Medium'
      WHEN lead_time_days <= 180 THEN 'Long'
      ELSE 'Very_Long'
    END                                    AS lead_time_bucket,
    -- Bucket stay length into categories
    CASE
      WHEN length_of_stay <= 2  THEN 'Weekend'
      WHEN length_of_stay <= 5  THEN 'Short_Stay'
      ELSE 'Extended'
    END                                    AS stay_bucket,
    hotel_type = 'Resort'                  AS label
  FROM HOTEL_INSIGHTS_DB.PUBLIC.BOOKINGS;
-- label=FALSE (City): ~8.0  |  label=TRUE (Resort): ~5.5-6.5


-- ============================================================
--  STEP 3 — Create Top Insights instance
-- ============================================================

CREATE OR REPLACE SNOWFLAKE.ML.TOP_INSIGHTS
  HOTEL_INSIGHTS_DB.PUBLIC.HOTEL_INSIGHTS();


-- ============================================================
--  STEP 4 — Run GET_DRIVERS (preview)
-- ============================================================

CALL HOTEL_INSIGHTS_DB.PUBLIC.HOTEL_INSIGHTS!GET_DRIVERS(
  INPUT_DATA     => TABLE(HOTEL_INSIGHTS_DB.PUBLIC.V_BOOKINGS),
  LABEL_COLNAME  => 'label',
  METRIC_COLNAME => 'satisfaction_score'
);


-- ============================================================
--  STEP 5 — Save results
-- ============================================================

CREATE OR REPLACE TABLE HOTEL_INSIGHTS_DB.PUBLIC.RESORT_CITY_DRIVERS AS
  SELECT * FROM TABLE(
    HOTEL_INSIGHTS_DB.PUBLIC.HOTEL_INSIGHTS!GET_DRIVERS(
      INPUT_DATA     => TABLE(HOTEL_INSIGHTS_DB.PUBLIC.V_BOOKINGS),
      LABEL_COLNAME  => 'label',
      METRIC_COLNAME => 'satisfaction_score'
    )
  );


-- ============================================================
--  STEP 6 — Query results
-- ============================================================

-- Overall satisfaction gap: Resort vs City
SELECT
  ROUND(METRIC_CONTROL, 1)        AS city_total,
  ROUND(METRIC_TEST, 1)           AS resort_total,
  ROUND(CONTRIBUTION, 1)          AS total_gap,
  ROUND(GROWTH_RATE * 100, 1)     AS resort_vs_city_pct
FROM HOTEL_INSIGHTS_DB.PUBLIC.RESORT_CITY_DRIVERS
WHERE CONTRIBUTOR = '["Overall"]';

-- Full ranked list — clean segments only (no negations like "not X = Y")
SELECT
  REPLACE(ARRAY_TO_STRING(PARSE_JSON(CONTRIBUTOR), ' & '), '_', ' ') AS segment,
  ROUND(METRIC_CONTROL, 1)               AS city_score,
  ROUND(METRIC_TEST, 1)                  AS resort_score,
  ROUND(CONTRIBUTION, 1)                 AS score_gap,
  ROUND(RELATIVE_CONTRIBUTION * 100, 1)  AS pct_of_total_gap,
  ROUND(GROWTH_RATE * 100, 1)            AS resort_vs_city_pct
FROM HOTEL_INSIGHTS_DB.PUBLIC.RESORT_CITY_DRIVERS
WHERE CONTRIBUTOR != '["Overall"]'
  AND METRIC_CONTROL > 0
  AND METRIC_TEST > 0
  AND CONTRIBUTOR NOT LIKE '%not %'
ORDER BY CONTRIBUTION ASC;

-- Problem segments: Resort scores more than 30% below City (both non-zero)
SELECT
  REPLACE(ARRAY_TO_STRING(PARSE_JSON(CONTRIBUTOR), ' & '), '_', ' ') AS segment,
  ROUND(METRIC_CONTROL, 1)        AS city_score,
  ROUND(METRIC_TEST, 1)           AS resort_score,
  ROUND(GROWTH_RATE * 100, 1)     AS resort_shortfall_pct
FROM HOTEL_INSIGHTS_DB.PUBLIC.RESORT_CITY_DRIVERS
WHERE CONTRIBUTION < 0
  AND CONTRIBUTOR != '["Overall"]'
  AND METRIC_CONTROL > 0
  AND METRIC_TEST > 0
  AND CONTRIBUTOR NOT LIKE '%not %'
  AND ABS(GROWTH_RATE) > 0.30
ORDER BY GROWTH_RATE ASC;

-- Bright spots — Resort segments closest to City scores
SELECT
  REPLACE(ARRAY_TO_STRING(PARSE_JSON(CONTRIBUTOR), ' & '), '_', ' ') AS segment,
  ROUND(METRIC_CONTROL, 1)        AS city_score,
  ROUND(METRIC_TEST, 1)           AS resort_score,
  ROUND(GROWTH_RATE * 100, 1)     AS resort_vs_city_pct
FROM HOTEL_INSIGHTS_DB.PUBLIC.RESORT_CITY_DRIVERS
WHERE CONTRIBUTOR != '["Overall"]'
  AND METRIC_CONTROL > 0
  AND METRIC_TEST > 0
  AND CONTRIBUTOR NOT LIKE '%not %'
ORDER BY ABS(GROWTH_RATE) ASC
LIMIT 5;

-- OTA channel deep-dive
SELECT
  REPLACE(ARRAY_TO_STRING(PARSE_JSON(CONTRIBUTOR), ' & '), '_', ' ') AS segment,
  ROUND(METRIC_CONTROL, 1)               AS city_score,
  ROUND(METRIC_TEST, 1)                  AS resort_score,
  ROUND(CONTRIBUTION, 1)                 AS score_gap,
  ROUND(RELATIVE_CONTRIBUTION * 100, 1)  AS pct_of_total_gap
FROM HOTEL_INSIGHTS_DB.PUBLIC.RESORT_CITY_DRIVERS
WHERE CONTRIBUTOR LIKE '%OTA%'
  AND METRIC_CONTROL > 0
  AND METRIC_TEST > 0
  AND CONTRIBUTOR NOT LIKE '%not %'
ORDER BY CONTRIBUTION ASC;


-- See all contributor values (for debugging)
SELECT DISTINCT ARRAY_TO_STRING(PARSE_JSON(CONTRIBUTOR), ' & ') AS segment
FROM HOTEL_INSIGHTS_DB.PUBLIC.RESORT_CITY_DRIVERS
ORDER BY segment;
