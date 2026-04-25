-- ============================================================
--  Snowflake ML Top Insights — Complete Demo
--  Two real-world examples:
--    A) Time-Series  : Why did monthly revenue change?
--                      Compare last 30 days vs prior 6 months
--                      across country, vertical, channel, tier
--    B) Vertical     : Why do EMEA & USA credit usage differ?
--                      Compare EMEA vs USA accounts
--                      across industry, company size, product
--  Database : INSIGHTS_DB
-- ============================================================

CREATE DATABASE IF NOT EXISTS INSIGHTS_DB;
USE DATABASE INSIGHTS_DB;
USE SCHEMA PUBLIC;


-- ============================================================
--  EXAMPLE A — TIME-SERIES ANALYSIS
--  Business question: "Revenue grew overall last month — but
--  which countries, verticals, and channels actually drove it?
--  And which segments quietly declined?"
-- ============================================================

-- ── A1. Create the revenue source table ─────────────────────

CREATE OR REPLACE TABLE INSIGHTS_DB.PUBLIC.REVENUE_DATA (
  sale_date     DATE,
  revenue       FLOAT,          -- metric we want to explain
  country       VARCHAR,        -- USA, UK, France, Canada, Germany, India
  vertical      VARCHAR,        -- Finance, Auto, Tech, Fashion, Healthcare
  channel       VARCHAR,        -- online, retail, partner, direct
  customer_tier VARCHAR,        -- enterprise, business, starter
  region        VARCHAR         -- AMER, EMEA, APAC
);

-- ── Historical baseline (label = FALSE) — 6 months ago ──────
-- Normal performance across all segments

INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(month, -7, CURRENT_DATE))  AS sale_date,
  UNIFORM(800, 1200, RANDOM())                             AS revenue,
  'USA'                                                    AS country,
  'Finance'                                                AS vertical,
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)] AS channel,
  'enterprise'                                             AS customer_tier,
  'AMER'                                                   AS region
FROM TABLE(GENERATOR(ROWCOUNT => 180));

INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(month, -7, CURRENT_DATE)),
  UNIFORM(600, 900, RANDOM()),
  'USA', 'Auto',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business', 'AMER'
FROM TABLE(GENERATOR(ROWCOUNT => 180));

INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(month, -7, CURRENT_DATE)),
  UNIFORM(400, 700, RANDOM()),
  'USA', 'Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter', 'AMER'
FROM TABLE(GENERATOR(ROWCOUNT => 180));

INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(month, -7, CURRENT_DATE)),
  UNIFORM(500, 800, RANDOM()),
  'USA', 'Fashion',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business', 'AMER'
FROM TABLE(GENERATOR(ROWCOUNT => 180));

INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(month, -7, CURRENT_DATE)),
  UNIFORM(300, 600, RANDOM()),
  'UK', 'Finance',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business', 'EMEA'
FROM TABLE(GENERATOR(ROWCOUNT => 180));

INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(month, -7, CURRENT_DATE)),
  UNIFORM(200, 500, RANDOM()),
  'France', 'Fashion',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter', 'EMEA'
FROM TABLE(GENERATOR(ROWCOUNT => 180));

INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(month, -7, CURRENT_DATE)),
  UNIFORM(250, 550, RANDOM()),
  'Germany', 'Auto',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business', 'EMEA'
FROM TABLE(GENERATOR(ROWCOUNT => 180));

INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(month, -7, CURRENT_DATE)),
  UNIFORM(150, 400, RANDOM()),
  'Canada', 'Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter', 'AMER'
FROM TABLE(GENERATOR(ROWCOUNT => 180));

INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(month, -7, CURRENT_DATE)),
  UNIFORM(100, 350, RANDOM()),
  'India', 'Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter', 'APAC'
FROM TABLE(GENERATOR(ROWCOUNT => 180));

-- ── Test period (label = TRUE) — last 30 days ───────────────
-- Intentional surges: USA Finance surges, USA Auto surges
-- Intentional drops : France drops sharply, Germany drops, India flat

-- USA Finance — big surge in test period (revenue 3x)
INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(day, -30, CURRENT_DATE)),
  UNIFORM(2800, 3400, RANDOM()),   -- up from 800-1200
  'USA', 'Finance',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'enterprise', 'AMER'
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- USA Auto — moderate surge (revenue 2x)
INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(day, -30, CURRENT_DATE)),
  UNIFORM(1400, 1800, RANDOM()),   -- up from 600-900
  'USA', 'Auto',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business', 'AMER'
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- USA Tech — slight decline
INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(day, -30, CURRENT_DATE)),
  UNIFORM(200, 400, RANDOM()),     -- down from 400-700
  'USA', 'Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter', 'AMER'
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- USA Fashion — stable
INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(day, -30, CURRENT_DATE)),
  UNIFORM(500, 800, RANDOM()),     -- same as baseline
  'USA', 'Fashion',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business', 'AMER'
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- UK — stable
INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(day, -30, CURRENT_DATE)),
  UNIFORM(280, 580, RANDOM()),
  'UK', 'Finance',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business', 'EMEA'
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- France — sharp drop (revenue 80% lower)
INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(day, -30, CURRENT_DATE)),
  UNIFORM(30, 80, RANDOM()),       -- down from 200-500
  'France', 'Fashion',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter', 'EMEA'
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- Germany — significant drop (revenue 70% lower)
INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(day, -30, CURRENT_DATE)),
  UNIFORM(50, 120, RANDOM()),      -- down from 250-550
  'Germany', 'Auto',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'business', 'EMEA'
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- Canada — slight drop
INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(day, -30, CURRENT_DATE)),
  UNIFORM(100, 300, RANDOM()),
  'Canada', 'Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter', 'AMER'
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- India — flat
INSERT INTO INSIGHTS_DB.PUBLIC.REVENUE_DATA
SELECT
  DATEADD(day, SEQ4(), DATEADD(day, -30, CURRENT_DATE)),
  UNIFORM(120, 370, RANDOM()),
  'India', 'Tech',
  ['online','retail','partner','direct'][MOD(ABS(RANDOM()),4)],
  'starter', 'APAC'
FROM TABLE(GENERATOR(ROWCOUNT => 30));


-- ── A2. Create labeled view for time-series analysis ─────────
-- label = TRUE  → last 30 days  (test group — what changed)
-- label = FALSE → before that   (control group — baseline)
-- Exclude sale_date — used only to derive label, not a dimension

CREATE OR REPLACE VIEW INSIGHTS_DB.PUBLIC.V_REVENUE_TIMESERIES AS
  SELECT
    revenue,                -- metric to explain
    country,                -- categorical dimension
    vertical,               -- categorical dimension
    channel,                -- categorical dimension
    customer_tier,          -- categorical dimension
    region,                 -- categorical dimension
    sale_date >= DATEADD(day, -30, CURRENT_DATE) AS label
  FROM INSIGHTS_DB.PUBLIC.REVENUE_DATA;

-- Quick check — how many rows in each group?
SELECT label, COUNT(*) AS row_count,
       ROUND(SUM(revenue), 0) AS total_revenue
FROM INSIGHTS_DB.PUBLIC.V_REVENUE_TIMESERIES
GROUP BY label ORDER BY label;


-- ── A3. Create Top Insights instance (once per schema) ───────

CREATE SNOWFLAKE.ML.TOP_INSIGHTS IF NOT EXISTS
  INSIGHTS_DB.PUBLIC.MY_INSIGHTS();


-- ── A4. Run GET_DRIVERS — time-series ───────────────────────
-- Expected findings:
--   Positive contributors : USA Finance, USA Auto
--   Negative contributors : France, Germany, not-USA overall

CALL INSIGHTS_DB.PUBLIC.MY_INSIGHTS!GET_DRIVERS(
  INPUT_DATA     => TABLE(INSIGHTS_DB.PUBLIC.V_REVENUE_TIMESERIES),
  LABEL_COLNAME  => 'label',
  METRIC_COLNAME => 'revenue'
);


-- ── A5. Save results to a table ──────────────────────────────

CREATE OR REPLACE TABLE INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS AS
  SELECT * FROM TABLE(
    INSIGHTS_DB.PUBLIC.MY_INSIGHTS!GET_DRIVERS(
      INPUT_DATA     => TABLE(INSIGHTS_DB.PUBLIC.V_REVENUE_TIMESERIES),
      LABEL_COLNAME  => 'label',
      METRIC_COLNAME => 'revenue'
    )
  );

-- Preview: top positive drivers
SELECT
  CONTRIBUTOR,
  ROUND(METRIC_CONTROL, 0)                    AS baseline_revenue,
  ROUND(METRIC_TEST, 0)                       AS recent_revenue,
  ROUND(CONTRIBUTION, 0)                      AS abs_impact,
  ROUND(RELATIVE_CONTRIBUTION * 100, 1)       AS pct_of_total_change,
  ROUND(GROWTH_RATE * 100, 1)                 AS growth_rate_pct,
  CASE
    WHEN CONTRIBUTION > 0 THEN 'Growing segment'
    ELSE 'Declining segment'
  END AS segment_trend
FROM INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS
ORDER BY CONTRIBUTION DESC;

-- Top 3 positive contributors
SELECT CONTRIBUTOR,
       ROUND(CONTRIBUTION, 0) AS impact,
       ROUND(GROWTH_RATE * 100, 1) AS growth_pct
FROM INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS
WHERE CONTRIBUTION > 0
  AND CONTRIBUTOR != '["Overall"]'
ORDER BY CONTRIBUTION DESC
LIMIT 3;

-- Top 3 segments dragging revenue down
SELECT CONTRIBUTOR,
       ROUND(CONTRIBUTION, 0) AS impact,
       ROUND(GROWTH_RATE * 100, 1) AS decline_pct
FROM INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS
WHERE CONTRIBUTION < 0
ORDER BY CONTRIBUTION ASC
LIMIT 3;


-- ============================================================
--  EXAMPLE B — VERTICAL ANALYSIS
--  Business question: "EMEA accounts use fewer Snowflake
--  credits than USA accounts. Which industry segments and
--  company sizes explain the gap?"
-- ============================================================

-- ── B1. Create accounts source table ────────────────────────

CREATE OR REPLACE TABLE INSIGHTS_DB.PUBLIC.ACCOUNTS (
  account_id    VARCHAR,
  region        VARCHAR,     -- USA or EMEA
  industry      VARCHAR,     -- Technology, Finance, Healthcare, Consumer, Manufacturing
  num_employees NUMBER,      -- continuous — model will auto-bucket ranges
  contract_yrs  NUMBER,      -- years on platform (continuous)
  support_tier  VARCHAR,     -- Gold, Silver, Bronze
  credits       FLOAT        -- metric: Snowflake credits consumed
);

-- USA accounts (control — label = FALSE)
INSERT INTO INSIGHTS_DB.PUBLIC.ACCOUNTS
SELECT
  'USA-' || SEQ4()                                                       AS account_id,
  'USA'                                                                   AS region,
  ['Technology','Finance','Healthcare','Consumer','Manufacturing'][MOD(ABS(RANDOM()),5)] AS industry,
  UNIFORM(100, 12000, RANDOM())                                           AS num_employees,
  UNIFORM(1, 8, RANDOM())                                                 AS contract_yrs,
  ['Gold','Silver','Bronze'][MOD(ABS(RANDOM()),3)]                        AS support_tier,
  UNIFORM(1000, 5000, RANDOM())                                           AS credits
FROM TABLE(GENERATOR(ROWCOUNT => 500));

-- EMEA accounts (test — label = TRUE)
-- Same segments but credits 30-60% lower on average
-- Except: EMEA Technology with large companies (>5000 emp) — comparable to USA
INSERT INTO INSIGHTS_DB.PUBLIC.ACCOUNTS
SELECT
  'EMEA-' || SEQ4()                                                      AS account_id,
  'EMEA'                                                                  AS region,
  ['Technology','Finance','Healthcare','Consumer','Manufacturing'][MOD(ABS(RANDOM()),5)] AS industry,
  UNIFORM(100, 12000, RANDOM())                                           AS num_employees,
  UNIFORM(1, 6, RANDOM())                                                 AS contract_yrs,
  ['Gold','Silver','Bronze'][MOD(ABS(RANDOM()),3)]                        AS support_tier,
  -- Small/mid EMEA companies use far fewer credits
  -- Large EMEA Technology companies use similar credits to USA
  CASE
    WHEN UNIFORM(100,12000,RANDOM()) > 8000
     AND ['Technology','Finance','Healthcare','Consumer','Manufacturing'][MOD(ABS(RANDOM()),5)] = 'Technology'
    THEN UNIFORM(900, 4500, RANDOM())    -- large tech EMEA ≈ USA
    WHEN UNIFORM(100,12000,RANDOM()) BETWEEN 4000 AND 8000
    THEN UNIFORM(300, 1800, RANDOM())    -- mid-size: significant gap
    ELSE UNIFORM(100, 900, RANDOM())     -- small EMEA: much lower
  END AS credits
FROM TABLE(GENERATOR(ROWCOUNT => 400));


-- ── B2. Create labeled view for vertical analysis ────────────
-- label = TRUE  → EMEA (test group — what we're explaining)
-- label = FALSE → USA  (control group — benchmark)
-- Cast num_employees to keep as continuous (already NUMBER — auto-detected)
-- Cast contract_yrs to VARCHAR to force categorical treatment

CREATE OR REPLACE VIEW INSIGHTS_DB.PUBLIC.V_ACCOUNTS_VERTICAL AS
  SELECT
    credits,                                  -- metric
    industry,                                 -- categorical
    num_employees,                            -- continuous (auto-bucketed)
    CAST(contract_yrs AS VARCHAR) AS contract_yrs_cat,  -- forced categorical
    support_tier,                             -- categorical
    region = 'EMEA' AS label
  FROM INSIGHTS_DB.PUBLIC.ACCOUNTS;

-- Quick check
SELECT label, COUNT(*) AS accounts,
       ROUND(AVG(credits), 0) AS avg_credits
FROM INSIGHTS_DB.PUBLIC.V_ACCOUNTS_VERTICAL
GROUP BY label ORDER BY label;


-- ── B3. Run GET_DRIVERS — vertical ───────────────────────────
-- Expected findings:
--   Segments with large negative contribution:
--     Small EMEA companies (num_employees < 4000)
--     EMEA Consumer and Manufacturing (widest gap vs USA)
--   Segments with smaller gap:
--     Large EMEA Technology companies

CALL INSIGHTS_DB.PUBLIC.MY_INSIGHTS!GET_DRIVERS(
  INPUT_DATA     => TABLE(INSIGHTS_DB.PUBLIC.V_ACCOUNTS_VERTICAL),
  LABEL_COLNAME  => 'label',
  METRIC_COLNAME => 'credits'
);


-- ── B4. Save results & query ─────────────────────────────────

CREATE OR REPLACE TABLE INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS AS
  SELECT * FROM TABLE(
    INSIGHTS_DB.PUBLIC.MY_INSIGHTS!GET_DRIVERS(
      INPUT_DATA     => TABLE(INSIGHTS_DB.PUBLIC.V_ACCOUNTS_VERTICAL),
      LABEL_COLNAME  => 'label',
      METRIC_COLNAME => 'credits'
    )
  );

-- Full results ordered by absolute impact
SELECT
  CONTRIBUTOR,
  ROUND(METRIC_CONTROL, 0)                AS usa_credits,
  ROUND(METRIC_TEST, 0)                   AS emea_credits,
  ROUND(CONTRIBUTION, 0)                  AS credit_gap,
  ROUND(RELATIVE_CONTRIBUTION * 100, 1)   AS pct_of_total_gap,
  ROUND(GROWTH_RATE * 100, 1)             AS emea_vs_usa_pct
FROM INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS
ORDER BY CONTRIBUTION ASC;   -- most negative gap first

-- Segments where EMEA significantly underperforms USA
SELECT CONTRIBUTOR,
       ROUND(METRIC_CONTROL, 0)   AS usa_credits,
       ROUND(METRIC_TEST, 0)      AS emea_credits,
       ROUND(GROWTH_RATE * 100, 1) AS emea_shortfall_pct
FROM INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS
WHERE CONTRIBUTION < 0
  AND CONTRIBUTOR != '["Overall"]'
  AND ABS(GROWTH_RATE) > 0.30    -- only segments with >30% gap
ORDER BY CONTRIBUTION ASC;

-- Overall summary
SELECT
  ROUND(METRIC_CONTROL, 0)  AS total_usa_credits,
  ROUND(METRIC_TEST, 0)     AS total_emea_credits,
  ROUND(CONTRIBUTION, 0)    AS total_gap,
  ROUND(GROWTH_RATE * 100, 1) AS overall_emea_vs_usa_pct
FROM INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS
WHERE CONTRIBUTOR = '["Overall"]';


-- ============================================================
--  BONUS — SCHEDULING WITH A TASK
--  Run time-series driver analysis automatically every Monday
--  morning so the business review pack is always pre-populated
-- ============================================================

CREATE OR REPLACE TASK INSIGHTS_DB.PUBLIC.WEEKLY_REVENUE_DRIVERS
  WAREHOUSE = COMPUTE_WH
  SCHEDULE  = 'USING CRON 0 6 * * MON UTC'
AS
  CREATE OR REPLACE TABLE INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS AS
    SELECT
      CURRENT_TIMESTAMP                         AS run_at,
      CONTRIBUTOR,
      ROUND(METRIC_CONTROL, 0)                  AS baseline_revenue,
      ROUND(METRIC_TEST, 0)                     AS recent_revenue,
      ROUND(CONTRIBUTION, 0)                    AS abs_impact,
      ROUND(RELATIVE_CONTRIBUTION * 100, 1)     AS pct_of_total_change,
      ROUND(GROWTH_RATE * 100, 1)               AS growth_rate_pct
    FROM TABLE(
      INSIGHTS_DB.PUBLIC.MY_INSIGHTS!GET_DRIVERS(
        INPUT_DATA     => TABLE(INSIGHTS_DB.PUBLIC.V_REVENUE_TIMESERIES),
        LABEL_COLNAME  => 'label',
        METRIC_COLNAME => 'revenue'
      )
    )
    ORDER BY ABS(CONTRIBUTION) DESC;

-- Enable task
ALTER TASK INSIGHTS_DB.PUBLIC.WEEKLY_REVENUE_DRIVERS RESUME;


-- ============================================================
--  VERIFY ROW COUNTS
-- ============================================================

SELECT 'REVENUE_DATA' AS tbl, COUNT(*) AS "rows" FROM INSIGHTS_DB.PUBLIC.REVENUE_DATA
UNION ALL
SELECT 'ACCOUNTS',           COUNT(*)          FROM INSIGHTS_DB.PUBLIC.ACCOUNTS
UNION ALL
SELECT 'REVENUE_DRIVERS',    COUNT(*)          FROM INSIGHTS_DB.PUBLIC.REVENUE_DRIVERS
UNION ALL
SELECT 'EMEA_USA_DRIVERS',   COUNT(*)          FROM INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS;
