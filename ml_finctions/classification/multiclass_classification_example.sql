--------------------------------------------------------------
-- SNOWFLAKE ML MULTI-CLASS CLASSIFICATION
-- SCENARIO: EMPLOYEE PERFORMANCE RATING PREDICTION
--------------------------------------------------------------

-- Step 1: Create database and schema
CREATE OR REPLACE DATABASE hr_intelligence;
CREATE OR REPLACE SCHEMA hr_intelligence.performance_analysis;
USE DATABASE hr_intelligence;
USE SCHEMA performance_analysis;

-- Step 2: Create training data (employee performance rating prediction)
CREATE OR REPLACE TABLE employee_training_data AS (
    SELECT
        UNIFORM(10000, 99999, RANDOM()) AS employee_id,
        ROUND(UNIFORM(22, 60, RANDOM()), 0) AS age,
        ROUND(UNIFORM(5, 20, RANDOM()), 0) AS years_experience,
        ROUND(UNIFORM(70, 100, RANDOM())::FLOAT, 1) AS training_score,
        UNIFORM(0, 2, RANDOM()) AS projects_completed,
        ROUND(UNIFORM(1, 3, RANDOM())::FLOAT, 1) AS avg_hours_overtime_per_week,
        CAST(UNIFORM(0, 3, RANDOM()) AS VARCHAR) AS department_code,
        'needs_improvement' AS performance_rating
    FROM TABLE(GENERATOR(rowCount => 150))
    UNION ALL
    SELECT
        UNIFORM(10000, 99999, RANDOM()) AS employee_id,
        ROUND(UNIFORM(25, 55, RANDOM()), 0) AS age,
        ROUND(UNIFORM(3, 15, RANDOM()), 0) AS years_experience,
        ROUND(UNIFORM(60, 85, RANDOM())::FLOAT, 1) AS training_score,
        UNIFORM(2, 5, RANDOM()) AS projects_completed,
        ROUND(UNIFORM(2, 6, RANDOM())::FLOAT, 1) AS avg_hours_overtime_per_week,
        CAST(UNIFORM(0, 3, RANDOM()) AS VARCHAR) AS department_code,
        'meets_expectations' AS performance_rating
    FROM TABLE(GENERATOR(rowCount => 200))
    UNION ALL
    SELECT
        UNIFORM(10000, 99999, RANDOM()) AS employee_id,
        ROUND(UNIFORM(28, 50, RANDOM()), 0) AS age,
        ROUND(UNIFORM(5, 25, RANDOM()), 0) AS years_experience,
        ROUND(UNIFORM(80, 100, RANDOM())::FLOAT, 1) AS training_score,
        UNIFORM(4, 8, RANDOM()) AS projects_completed,
        ROUND(UNIFORM(4, 10, RANDOM())::FLOAT, 1) AS avg_hours_overtime_per_week,
        CAST(UNIFORM(1, 3, RANDOM()) AS VARCHAR) AS department_code,
        'exceeds_expectations' AS performance_rating
    FROM TABLE(GENERATOR(rowCount => 150))
    UNION ALL
    SELECT
        UNIFORM(10000, 99999, RANDOM()) AS employee_id,
        ROUND(UNIFORM(30, 55, RANDOM()), 0) AS age,
        ROUND(UNIFORM(8, 30, RANDOM()), 0) AS years_experience,
        ROUND(UNIFORM(90, 100, RANDOM())::FLOAT, 1) AS training_score,
        UNIFORM(6, 12, RANDOM()) AS projects_completed,
        ROUND(UNIFORM(5, 15, RANDOM())::FLOAT, 1) AS avg_hours_overtime_per_week,
        CAST(UNIFORM(2, 3, RANDOM()) AS VARCHAR) AS department_code,
        'outstanding' AS performance_rating
    FROM TABLE(GENERATOR(rowCount => 100))
);

SELECT performance_rating, COUNT(*) AS cnt
FROM employee_training_data
GROUP BY performance_rating
ORDER BY cnt DESC;

-- Step 3: Create training view (exclude employee_id)
CREATE OR REPLACE VIEW performance_training_view AS
    SELECT
        age,
        years_experience,
        training_score,
        projects_completed,
        avg_hours_overtime_per_week,
        department_code,
        performance_rating
    FROM employee_training_data;

SELECT * FROM performance_training_view ORDER BY RANDOM(42) LIMIT 10;

-- Step 4: Create prediction data (new employees without ratings)
CREATE OR REPLACE TABLE employee_prediction_data AS (
    SELECT
        UNIFORM(10000, 99999, RANDOM()) AS employee_id,
        ROUND(UNIFORM(22, 60, RANDOM()), 0) AS age,
        ROUND(UNIFORM(1, 30, RANDOM()), 0) AS years_experience,
        ROUND(UNIFORM(50, 100, RANDOM())::FLOAT, 1) AS training_score,
        UNIFORM(0, 12, RANDOM()) AS projects_completed,
        ROUND(UNIFORM(1, 15, RANDOM())::FLOAT, 1) AS avg_hours_overtime_per_week,
        CAST(UNIFORM(0, 3, RANDOM()) AS VARCHAR) AS department_code
    FROM TABLE(GENERATOR(rowCount => 200))
);

SELECT * FROM employee_prediction_data LIMIT 5;

-- Step 5: Train multi-class classification model
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION performance_classifier(
    INPUT_DATA => SYSTEM$REFERENCE('view', 'performance_training_view'),
    TARGET_COLNAME => 'PERFORMANCE_RATING'
);

-- Step 6: Run predictions on new employees
SELECT *, performance_classifier!PREDICT(INPUT_DATA => {*})
    AS prediction FROM employee_prediction_data
LIMIT 10;

-- Step 7: Save all predictions to a table
CREATE OR REPLACE TABLE performance_predictions AS
SELECT *, performance_classifier!PREDICT(INPUT_DATA => {*})
    AS prediction FROM employee_prediction_data;

-- Step 8: Parse multi-class prediction results
SELECT
    employee_id,
    age,
    years_experience,
    training_score,
    projects_completed,
    prediction:class::STRING AS predicted_rating,
    ROUND(prediction:probability:needs_improvement, 4) AS prob_needs_improvement,
    ROUND(prediction:probability:meets_expectations, 4) AS prob_meets_expectations,
    ROUND(prediction:probability:exceeds_expectations, 4) AS prob_exceeds_expectations,
    ROUND(prediction:probability:outstanding, 4) AS prob_outstanding
FROM performance_predictions
ORDER BY prob_outstanding DESC
LIMIT 20;

-- Step 9: Distribution of predicted ratings
SELECT
    prediction:class::STRING AS predicted_rating,
    COUNT(*) AS employee_count
FROM performance_predictions
GROUP BY predicted_rating
ORDER BY employee_count DESC;

-- Step 10: Evaluate model - per-class metrics
CALL performance_classifier!SHOW_EVALUATION_METRICS();

-- Step 11: Evaluate model - global metrics
CALL performance_classifier!SHOW_GLOBAL_EVALUATION_METRICS();

-- Step 12: Confusion matrix
CALL performance_classifier!SHOW_CONFUSION_MATRIX();

-- Step 13: Threshold metrics
CALL performance_classifier!SHOW_THRESHOLD_METRICS();

-- Step 14: Feature importance
CALL performance_classifier!SHOW_FEATURE_IMPORTANCE();

-- Step 15: Training logs
CALL performance_classifier!SHOW_TRAINING_LOGS();

-- Step 16: Cleanup (optional)
-- DROP SNOWFLAKE.ML.CLASSIFICATION performance_classifier;
-- DROP DATABASE hr_intelligence;
