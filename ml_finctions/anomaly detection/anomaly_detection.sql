-- ============================================================
-- SNOWFLAKE.ML.ANOMALY_DETECTION — Full SQL Demo
-- ============================================================

-- 1. Setup: Create database and schema
CREATE OR REPLACE DATABASE ANOMALY_DB;
USE DATABASE ANOMALY_DB;
USE SCHEMA PUBLIC;

-- 2. Create training table (90 days of normal daily sales)
CREATE OR REPLACE TABLE DAILY_SALES (
  sale_date    TIMESTAMP_NTZ,
  sales_amount FLOAT
) AS
SELECT
  DATEADD('day', seq4(), '2024-01-01')::TIMESTAMP_NTZ,
  ROUND(200 + UNIFORM(-20, 20, RANDOM()) +
    CASE WHEN DAYOFWEEK(DATEADD('day', seq4(), '2024-01-01')) IN (0, 6) THEN 50 ELSE 0 END, 2)
FROM TABLE(GENERATOR(ROWCOUNT => 90));

-- 3. Create test table (30 days with injected anomalies on specific days)
CREATE OR REPLACE TABLE DAILY_SALES_TEST (
  sale_date    TIMESTAMP_NTZ,
  sales_amount FLOAT
) AS
SELECT
  DATEADD('day', seq4() + 90, '2024-01-01')::TIMESTAMP_NTZ,
  CASE
    WHEN seq4() IN (3, 10, 20) THEN 500   -- spike anomalies
    WHEN seq4() IN (7, 15, 25) THEN 50    -- dip anomalies
    ELSE ROUND(200 + UNIFORM(-20, 20, RANDOM()) +
         CASE WHEN DAYOFWEEK(DATEADD('day', seq4() + 90, '2024-01-01')) IN (0, 6) THEN 50 ELSE 0 END, 2)
  END
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- 4. Quick look at the data
SELECT * FROM DAILY_SALES ORDER BY sale_date LIMIT 10;
SELECT * FROM DAILY_SALES_TEST ORDER BY sale_date;

-- 5. Train the anomaly detection model (unsupervised — no label column)
CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION SALES_ANOMALY_MODEL(
  INPUT_DATA        => SYSTEM$REFERENCE('TABLE', 'ANOMALY_DB.PUBLIC.DAILY_SALES'),
  TIMESTAMP_COLNAME => 'SALE_DATE',
  TARGET_COLNAME    => 'SALES_AMOUNT',
  LABEL_COLNAME     => ''
);

-- 6. Detect anomalies in the test data
CALL SALES_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA        => SYSTEM$REFERENCE('TABLE', 'ANOMALY_DB.PUBLIC.DAILY_SALES_TEST'),
  TIMESTAMP_COLNAME => 'SALE_DATE',
  TARGET_COLNAME    => 'SALES_AMOUNT'
);

-- 7. Save results to a table for easier querying
CREATE OR REPLACE TABLE ANOMALY_RESULTS AS
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- 8. View all detected anomalies
SELECT
  TS            AS sale_date,
  Y             AS actual_sales,
  FORECAST      AS expected_sales,
  LOWER_BOUND,
  UPPER_BOUND,
  IS_ANOMALY,
  PERCENTILE,
  DISTANCE
FROM ANOMALY_RESULTS
WHERE IS_ANOMALY = TRUE
ORDER BY TS;

-- 9. Summary: count of anomalies vs normal
SELECT
  IS_ANOMALY,
  COUNT(*) AS day_count
FROM ANOMALY_RESULTS
GROUP BY IS_ANOMALY;

-- 10. Side-by-side: test data with anomaly flags
SELECT
  t.sale_date,
  t.sales_amount AS actual,
  r.FORECAST     AS expected,
  r.IS_ANOMALY,
  CASE
    WHEN r.IS_ANOMALY AND t.sales_amount > r.FORECAST THEN 'SPIKE'
    WHEN r.IS_ANOMALY AND t.sales_amount < r.FORECAST THEN 'DIP'
    ELSE 'NORMAL'
  END AS anomaly_type
FROM DAILY_SALES_TEST t
JOIN ANOMALY_RESULTS r ON t.sale_date = r.TS
ORDER BY t.sale_date;
