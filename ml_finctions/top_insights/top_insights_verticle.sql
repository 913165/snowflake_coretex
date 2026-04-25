-- ============================================================
--  Snowflake ML Top Insights — VERTICAL DEMO
--  Question : EMEA accounts use fewer Snowflake credits than
--             USA accounts. Which industry segments and
--             company sizes explain the gap?
--  Run this file top to bottom independently.
--  No other file needed.
-- ============================================================

CREATE DATABASE IF NOT EXISTS VERTICAL_INSIGHTS_DB;
USE DATABASE VERTICAL_INSIGHTS_DB;
USE SCHEMA PUBLIC;

-- ============================================================
--  STEP 1 — Create & load accounts table
--  500 USA accounts (control) + 400 EMEA accounts (test)
-- ============================================================

CREATE OR REPLACE TABLE VERTICAL_INSIGHTS_DB.PUBLIC.ACCOUNTS (
  account_id    VARCHAR,
  region        VARCHAR,   -- 'USA' or 'EMEA'
  industry      VARCHAR,   -- Technology, Finance, Healthcare, Consumer, Manufacturing
  num_employees NUMBER,    -- continuous — model auto-buckets into ranges
  contract_yrs  NUMBER,    -- years on platform
  support_tier  VARCHAR,   -- Gold, Silver, Bronze
  credits       FLOAT      -- METRIC: Snowflake credits consumed
);

-- USA accounts — will be CONTROL group (label = FALSE)
INSERT INTO VERTICAL_INSIGHTS_DB.PUBLIC.ACCOUNTS
SELECT
  'USA-' || SEQ4(),
  'USA',
  ['Technology','Finance','Healthcare','Consumer','Manufacturing'][MOD(ABS(RANDOM()),5)],
  UNIFORM(100,12000,RANDOM()),
  UNIFORM(1,8,RANDOM()),
  ['Gold','Silver','Bronze'][MOD(ABS(RANDOM()),3)],
  UNIFORM(1000,5000,RANDOM())
FROM TABLE(GENERATOR(ROWCOUNT=>500));

-- EMEA accounts — will be TEST group (label = TRUE)
-- Small EMEA companies  (< 4000 emp) → credits much lower than USA
-- Mid-size EMEA         (4000-8000)  → significant gap vs USA
-- Large EMEA Technology (> 8000 emp) → closest to USA (smallest gap)
INSERT INTO VERTICAL_INSIGHTS_DB.PUBLIC.ACCOUNTS
SELECT
  'EMEA-' || SEQ4(),
  'EMEA',
  ['Technology','Finance','Healthcare','Consumer','Manufacturing'][MOD(ABS(RANDOM()),5)],
  UNIFORM(100,12000,RANDOM()),
  UNIFORM(1,6,RANDOM()),
  ['Gold','Silver','Bronze'][MOD(ABS(RANDOM()),3)],
  CASE
    WHEN UNIFORM(100,12000,RANDOM()) > 8000
     AND ['Technology','Finance','Healthcare','Consumer','Manufacturing']
           [MOD(ABS(RANDOM()),5)] = 'Technology'
    THEN UNIFORM(900,4500,RANDOM())   -- large tech EMEA ≈ USA
    WHEN UNIFORM(100,12000,RANDOM()) BETWEEN 4000 AND 8000
    THEN UNIFORM(300,1800,RANDOM())   -- mid-size: significant gap
    ELSE UNIFORM(100,900,RANDOM())    -- small EMEA: much lower credits
  END
FROM TABLE(GENERATOR(ROWCOUNT=>400));

-- Verify: USA avg ~3000 credits, EMEA avg ~1000-1500
SELECT
  region,
  COUNT(*)                  AS accounts,
  ROUND(AVG(credits),0)     AS avg_credits,
  ROUND(MIN(credits),0)     AS min_credits,
  ROUND(MAX(credits),0)     AS max_credits
FROM VERTICAL_INSIGHTS_DB.PUBLIC.ACCOUNTS
GROUP BY region ORDER BY region;


-- ============================================================
--  STEP 2 — Create labeled view
--  label = TRUE  → EMEA  (test group   — what we explain)
--  label = FALSE → USA   (control group — the benchmark)
--
--  num_employees → NUMBER → auto-bucketed into meaningful ranges
--  contract_yrs  → cast to VARCHAR → forced categorical
--  account_id & region excluded — not useful dimensions
-- ============================================================

CREATE OR REPLACE VIEW VERTICAL_INSIGHTS_DB.PUBLIC.V_ACCOUNTS AS
  SELECT
    credits,
    industry,
    num_employees,
    CAST(contract_yrs AS VARCHAR) AS contract_yrs,
    support_tier,
    region = 'EMEA' AS label
  FROM VERTICAL_INSIGHTS_DB.PUBLIC.ACCOUNTS;

-- Confirm label split
SELECT
  label,
  COUNT(*)               AS accounts,
  ROUND(AVG(credits),0)  AS avg_credits,
  ROUND(SUM(credits),0)  AS total_credits
FROM VERTICAL_INSIGHTS_DB.PUBLIC.V_ACCOUNTS
GROUP BY label ORDER BY label;
-- label=FALSE (USA): ~3000 avg  |  label=TRUE (EMEA): ~1000-1500 avg


-- ============================================================
--  STEP 3 — Create Top Insights instance
-- ============================================================

CREATE OR REPLACE SNOWFLAKE.ML.TOP_INSIGHTS
  VERTICAL_INSIGHTS_DB.PUBLIC.VERTICAL_INSIGHTS();


-- ============================================================
--  STEP 4 — Run GET_DRIVERS
-- ============================================================

CALL VERTICAL_INSIGHTS_DB.PUBLIC.VERTICAL_INSIGHTS!GET_DRIVERS(
  INPUT_DATA     => TABLE(VERTICAL_INSIGHTS_DB.PUBLIC.V_ACCOUNTS),
  LABEL_COLNAME  => 'label',
  METRIC_COLNAME => 'credits'
);


-- ============================================================
--  STEP 5 — Save results
-- ============================================================

CREATE OR REPLACE TABLE VERTICAL_INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS AS
  SELECT * FROM TABLE(
    VERTICAL_INSIGHTS_DB.PUBLIC.VERTICAL_INSIGHTS!GET_DRIVERS(
      INPUT_DATA     => TABLE(VERTICAL_INSIGHTS_DB.PUBLIC.V_ACCOUNTS),
      LABEL_COLNAME  => 'label',
      METRIC_COLNAME => 'credits'
    )
  );


-- ============================================================
--  STEP 6 — Query results
-- ============================================================

-- Overall summary — total EMEA vs USA gap
SELECT
  ROUND(METRIC_CONTROL,0)       AS total_usa_credits,
  ROUND(METRIC_TEST,0)          AS total_emea_credits,
  ROUND(CONTRIBUTION,0)         AS total_gap,
  ROUND(GROWTH_RATE*100,1)      AS overall_emea_vs_usa_pct
FROM VERTICAL_INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS
WHERE CONTRIBUTOR = '["Overall"]';

-- Full ranked list — most negative gap first
SELECT
  CONTRIBUTOR,
  ROUND(METRIC_CONTROL,0)               AS usa_credits,
  ROUND(METRIC_TEST,0)                  AS emea_credits,
  ROUND(CONTRIBUTION,0)                 AS credit_gap,
  ROUND(RELATIVE_CONTRIBUTION*100,1)    AS pct_of_total_gap,
  ROUND(GROWTH_RATE*100,1)              AS emea_vs_usa_pct
FROM VERTICAL_INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS
ORDER BY CONTRIBUTION ASC;

-- Segments where EMEA underperforms by more than 30%
SELECT
  CONTRIBUTOR,
  ROUND(METRIC_CONTROL,0)       AS usa_credits,
  ROUND(METRIC_TEST,0)          AS emea_credits,
  ROUND(GROWTH_RATE*100,1)      AS emea_shortfall_pct
FROM VERTICAL_INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS
WHERE CONTRIBUTION < 0
  AND CONTRIBUTOR != '["Overall"]'
  AND ABS(GROWTH_RATE) > 0.30
ORDER BY CONTRIBUTION ASC;

-- Segments where EMEA is closest to USA (smallest gap)
SELECT
  CONTRIBUTOR,
  ROUND(METRIC_CONTROL,0)       AS usa_credits,
  ROUND(METRIC_TEST,0)          AS emea_credits,
  ROUND(GROWTH_RATE*100,1)      AS emea_vs_usa_pct
FROM VERTICAL_INSIGHTS_DB.PUBLIC.EMEA_USA_DRIVERS
WHERE CONTRIBUTOR != '["Overall"]'
ORDER BY ABS(GROWTH_RATE) ASC
LIMIT 5;
