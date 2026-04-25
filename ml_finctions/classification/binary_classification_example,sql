--------------------------------------------------------------
-- SNOWFLAKE ML BINARY CLASSIFICATION - CUSTOMER CHURN ANALYSIS
--------------------------------------------------------------
-- Step 1: Create database and schema
CREATE OR REPLACE DATABASE customer_analytics;
CREATE OR REPLACE SCHEMA customer_analytics.churn_analysis;
USE DATABASE customer_analytics;
USE SCHEMA churn_analysis;

-- Step 2: Create training data (customer churn prediction scenario)
CREATE OR REPLACE TABLE training_data AS (
    SELECT
        UNIFORM(1, 1000, RANDOM()) AS customer_id,
        ROUND(UNIFORM(18, 70, RANDOM()), 0) AS age,
        ROUND(UNIFORM(1, 120, RANDOM()), 0) AS months_as_customer,
        ROUND(UNIFORM(0, 50, RANDOM())::FLOAT, 2) AS monthly_charges,
        UNIFORM(0, 5, RANDOM()) AS support_tickets,
        CAST(UNIFORM(0, 2, RANDOM()) AS VARCHAR) AS contract_type,
        FALSE AS churned
    FROM TABLE(GENERATOR(rowCount => 200))
    UNION ALL
    SELECT
        UNIFORM(1001, 2000, RANDOM()) AS customer_id,
        ROUND(UNIFORM(18, 70, RANDOM()), 0) AS age,
        ROUND(UNIFORM(1, 12, RANDOM()), 0) AS months_as_customer,
        ROUND(UNIFORM(50, 100, RANDOM())::FLOAT, 2) AS monthly_charges,
        UNIFORM(3, 10, RANDOM()) AS support_tickets,
        CAST(UNIFORM(0, 1, RANDOM()) AS VARCHAR) AS contract_type,
        TRUE AS churned
    FROM TABLE(GENERATOR(rowCount => 200))
);

SELECT * FROM training_data ORDER BY RANDOM(42) LIMIT 10;

-- Step 3: Create a view for binary classification training
CREATE OR REPLACE VIEW binary_training_view AS
    SELECT age, months_as_customer, monthly_charges, support_tickets, contract_type, churned
    FROM training_data;

SELECT * FROM binary_training_view ORDER BY RANDOM(42) LIMIT 5;

-- Step 4: Create prediction (inference) data without labels
CREATE OR REPLACE TABLE prediction_data AS (
    SELECT
        UNIFORM(2001, 3000, RANDOM()) AS customer_id,
        ROUND(UNIFORM(18, 70, RANDOM()), 0) AS age,
        ROUND(UNIFORM(1, 120, RANDOM()), 0) AS months_as_customer,
        ROUND(UNIFORM(0, 100, RANDOM())::FLOAT, 2) AS monthly_charges,
        UNIFORM(0, 10, RANDOM()) AS support_tickets,
        CAST(UNIFORM(0, 2, RANDOM()) AS VARCHAR) AS contract_type
    FROM TABLE(GENERATOR(rowCount => 100))
);

SELECT * FROM prediction_data LIMIT 5;

-- Step 5: Train the binary classification model
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION churn_classifier(
    INPUT_DATA => SYSTEM$REFERENCE('view', 'binary_training_view'),
    TARGET_COLNAME => 'CHURNED'
);

-- Step 6: Run predictions on new data
SELECT *, churn_classifier!PREDICT(INPUT_DATA => {*})
    AS prediction FROM prediction_data
LIMIT 10;

-- Step 7: Save predictions to a table
CREATE OR REPLACE TABLE churn_predictions AS
SELECT *, churn_classifier!PREDICT(INPUT_DATA => {*})
    AS prediction FROM prediction_data;

-- Step 8: Explore predictions - extract class and probabilities
SELECT
    customer_id,
    age,
    monthly_charges,
    support_tickets,
    prediction:class::STRING AS predicted_churn,
    ROUND(prediction:probability:true, 4) AS churn_probability,
    ROUND(prediction:probability:false, 4) AS no_churn_probability
FROM churn_predictions
ORDER BY churn_probability DESC
LIMIT 20;

-- Step 9: Evaluate the model
CALL churn_classifier!SHOW_EVALUATION_METRICS();

CALL churn_classifier!SHOW_GLOBAL_EVALUATION_METRICS();

CALL churn_classifier!SHOW_CONFUSION_MATRIX();

CALL churn_classifier!SHOW_THRESHOLD_METRICS();

-- Step 10: View feature importance
CALL churn_classifier!SHOW_FEATURE_IMPORTANCE();


