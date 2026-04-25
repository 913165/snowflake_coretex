-- ============================================================
--  Snowflake ML Top Insights — TIME-SERIES DEMO
--  Question : Revenue grew overall last month — but which
--             countries, verticals and channels drove it?
--             And which segments quietly declined?
--  Run this file top to bottom independently.
--  No other file needed.
-- ============================================================

CREATE DATABASE IF NOT EXISTS TIMESERIES_INSIGHTS_DB;
USE DATABASE TIMESERIES_INSIGHTS_DB;
USE SCHEMA PUBLIC;

-- ============================================================
--  STEP 1 — Create & load revenue table
--  1,890 rows: 9 segments × 180 baseline days + 30 test days
-- ============================================================

CREATE OR REPLACE TABLE TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA (
  sale_date     DATE,
  revenue       FLOAT,
  country       VARCHAR,
  vertical      VARCHAR,
  channel       VARCHAR,
  customer_tier VARCHAR,
  region        VARCHAR
);

-- Historical baseline rows (label will = FALSE — 6 months of normal)
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(month,-7,CURRENT_DATE)),
  UNIFORM(800,1200,RANDOM()),'USA','Finance',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'enterprise','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>180));

INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(month,-7,CURRENT_DATE)),
  UNIFORM(600,900,RANDOM()),'USA','Auto',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>180));

INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(month,-7,CURRENT_DATE)),
  UNIFORM(400,700,RANDOM()),'USA','Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>180));

INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(month,-7,CURRENT_DATE)),
  UNIFORM(500,800,RANDOM()),'USA','Fashion',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>180));

INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(month,-7,CURRENT_DATE)),
  UNIFORM(300,600,RANDOM()),'UK','Finance',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business','EMEA'
FROM TABLE(GENERATOR(ROWCOUNT=>180));

INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(month,-7,CURRENT_DATE)),
  UNIFORM(200,500,RANDOM()),'France','Fashion',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter','EMEA'
FROM TABLE(GENERATOR(ROWCOUNT=>180));

INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(month,-7,CURRENT_DATE)),
  UNIFORM(250,550,RANDOM()),'Germany','Auto',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business','EMEA'
FROM TABLE(GENERATOR(ROWCOUNT=>180));

INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(month,-7,CURRENT_DATE)),
  UNIFORM(150,400,RANDOM()),'Canada','Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>180));

INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(month,-7,CURRENT_DATE)),
  UNIFORM(100,350,RANDOM()),'India','Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter','APAC'
FROM TABLE(GENERATOR(ROWCOUNT=>180));

-- Test period rows (label will = TRUE — last 30 days, engineered changes)
-- USA Finance  → surges 3x  (big positive driver)
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(day,-30,CURRENT_DATE)),
  UNIFORM(2800,3400,RANDOM()),'USA','Finance',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'enterprise','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>30));

-- USA Auto     → surges 2x  (positive driver)
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(day,-30,CURRENT_DATE)),
  UNIFORM(1400,1800,RANDOM()),'USA','Auto',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>30));

-- USA Tech     → slight dip
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(day,-30,CURRENT_DATE)),
  UNIFORM(200,400,RANDOM()),'USA','Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>30));

-- USA Fashion  → stable
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(day,-30,CURRENT_DATE)),
  UNIFORM(500,800,RANDOM()),'USA','Fashion',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>30));

-- UK           → stable
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(day,-30,CURRENT_DATE)),
  UNIFORM(280,580,RANDOM()),'UK','Finance',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business','EMEA'
FROM TABLE(GENERATOR(ROWCOUNT=>30));

-- France       → drops 80%  (big negative driver)
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(day,-30,CURRENT_DATE)),
  UNIFORM(30,80,RANDOM()),'France','Fashion',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter','EMEA'
FROM TABLE(GENERATOR(ROWCOUNT=>30));

-- Germany      → drops 70%  (negative driver)
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(day,-30,CURRENT_DATE)),
  UNIFORM(50,120,RANDOM()),'Germany','Auto',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business','EMEA'
FROM TABLE(GENERATOR(ROWCOUNT=>30));

-- Canada       → slight dip
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(day,-30,CURRENT_DATE)),
  UNIFORM(100,300,RANDOM()),'Canada','Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter','AMER'
FROM TABLE(GENERATOR(ROWCOUNT=>30));

-- India        → flat
INSERT INTO TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT DATEADD(day,SEQ4(),DATEADD(day,-30,CURRENT_DATE)),
  UNIFORM(120,370,RANDOM()),'India','Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter','APAC'
FROM TABLE(GENERATOR(ROWCOUNT=>30));

-- Verify: should show ~1620 baseline rows + ~270 test rows
SELECT
  CASE WHEN sale_date >= DATEADD(day,-30,CURRENT_DATE)
       THEN 'TEST (last 30 days)'
       ELSE 'CONTROL (baseline)' END AS period,
  COUNT(*)                           AS row_count,
  ROUND(SUM(revenue),0)              AS total_revenue
FROM TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA
GROUP BY 1 ORDER BY 1;


-- ============================================================
--  STEP 2 — Create labeled view
--  label = TRUE  → last 30 days  (test  — what changed)
--  label = FALSE → before that   (control — baseline)
-- ============================================================

CREATE OR REPLACE VIEW TIMESERIES_INSIGHTS_DB.PUBLIC.V_REVENUE_TS AS
  SELECT
    revenue,
    country,
    vertical,
    channel,
    customer_tier,
    region,
    sale_date >= DATEADD(day,-30,CURRENT_DATE) AS label
  FROM TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DATA;


-- ============================================================
--  STEP 3 — Create Top Insights instance
-- ============================================================

CREATE OR REPLACE SNOWFLAKE.ML.TOP_INSIGHTS
  TIMESERIES_INSIGHTS_DB.PUBLIC.TS_INSIGHTS();


-- ============================================================
--  STEP 4 — Run GET_DRIVERS
-- ============================================================

CALL TIMESERIES_INSIGHTS_DB.PUBLIC.TS_INSIGHTS!GET_DRIVERS(
  INPUT_DATA     => TABLE(TIMESERIES_INSIGHTS_DB.PUBLIC.V_REVENUE_TS),
  LABEL_COLNAME  => 'label',
  METRIC_COLNAME => 'revenue'
);


-- ============================================================
--  STEP 5 — Save results
-- ============================================================

CREATE OR REPLACE TABLE TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS AS
  SELECT * FROM TABLE(
    TIMESERIES_INSIGHTS_DB.PUBLIC.TS_INSIGHTS!GET_DRIVERS(
      INPUT_DATA     => TABLE(TIMESERIES_INSIGHTS_DB.PUBLIC.V_REVENUE_TS),
      LABEL_COLNAME  => 'label',
      METRIC_COLNAME => 'revenue'
    )
  );


-- ============================================================
--  STEP 6 — Query results
-- ============================================================

-- Full ranked list of all segments
SELECT
  CONTRIBUTOR,
  ROUND(METRIC_CONTROL,0)               AS baseline_revenue,
  ROUND(METRIC_TEST,0)                  AS recent_revenue,
  ROUND(CONTRIBUTION,0)                 AS abs_impact,
  ROUND(RELATIVE_CONTRIBUTION*100,1)    AS pct_of_total_change,
  ROUND(GROWTH_RATE*100,1)              AS growth_rate_pct,
  CASE WHEN CONTRIBUTION > 0 THEN 'Growing' ELSE 'Declining' END AS trend
FROM TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS
ORDER BY CONTRIBUTION DESC;

-- Top 3 segments driving revenue UP
SELECT
  CONTRIBUTOR,
  ROUND(CONTRIBUTION,0)       AS impact,
  ROUND(GROWTH_RATE*100,1)    AS growth_pct
FROM TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS
WHERE CONTRIBUTION > 0
  AND CONTRIBUTOR != '["Overall"]'
ORDER BY CONTRIBUTION DESC
LIMIT 3;

-- Top 3 segments dragging revenue DOWN
SELECT
  CONTRIBUTOR,
  ROUND(CONTRIBUTION,0)       AS impact,
  ROUND(GROWTH_RATE*100,1)    AS decline_pct
FROM TIMESERIES_INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS
WHERE CONTRIBUTION < 0
ORDER BY CONTRIBUTION ASC
LIMIT 3;
