-- ============================================================
--  Snowflake ML Classification — BINARY (FIXED)
--  Fix: balanced training data 40 TRUE / 40 FALSE
--       stronger feature signals in new tickets
--       lower risk thresholds (0.55 / 0.35)
--  Database : SUPPORT_DB
-- ============================================================
CREATE OR REPLACE DATABASE SUPPORT_DB;
USE DATABASE SUPPORT_DB;
USE SCHEMA PUBLIC;

-- ============================================================
--  STEP 1 — Balanced training table
--  40 escalated (TRUE) + 40 not escalated (FALSE) = 80 rows
-- ============================================================

CREATE OR REPLACE TABLE SUPPORT_DB.PUBLIC.TICKET_TRAINING (
  ticket_id         VARCHAR,
  channel           VARCHAR,
  product           VARCHAR,
  region            VARCHAR,
  customer_tier     VARCHAR,
  issue_category    VARCHAR,
  response_time_hrs FLOAT,
  num_replies       NUMBER,
  reopened          BOOLEAN,
  sentiment_score   FLOAT,
  escalated         BOOLEAN    -- TARGET
);

INSERT INTO SUPPORT_DB.PUBLIC.TICKET_TRAINING VALUES

-- ── ESCALATED = TRUE (40 rows) ───────────────────────────────
-- Strong signals: high response_time, many replies, reopened, very negative sentiment, enterprise tier
('T001','phone',  'core_platform','AMER','enterprise','bug',         18.5, 12, TRUE,  -0.82, TRUE),
('T002','email',  'api',          'EMEA','enterprise','performance', 24.0,  9, TRUE,  -0.76, TRUE),
('T003','phone',  'billing',      'AMER','enterprise','billing',     36.0, 14, TRUE,  -0.90, TRUE),
('T004','portal', 'core_platform','APAC','enterprise','bug',         22.0, 11, TRUE,  -0.68, TRUE),
('T005','phone',  'api',          'AMER','enterprise','performance', 28.0, 13, FALSE, -0.85, TRUE),
('T006','email',  'core_platform','EMEA','enterprise','bug',         20.0, 10, TRUE,  -0.72, TRUE),
('T007','phone',  'mobile',       'AMER','enterprise','bug',         30.0, 15, TRUE,  -0.88, TRUE),
('T008','phone',  'billing',      'EMEA','enterprise','billing',     42.0, 16, TRUE,  -0.91, TRUE),
('T009','email',  'api',          'AMER','enterprise','bug',         19.0,  9, FALSE, -0.70, TRUE),
('T010','portal', 'core_platform','AMER','enterprise','performance', 26.0, 12, TRUE,  -0.78, TRUE),
('T011','phone',  'core_platform','EMEA','business',  'bug',         15.0, 10, TRUE,  -0.65, TRUE),
('T012','email',  'api',          'APAC','enterprise','performance', 33.0, 14, TRUE,  -0.80, TRUE),
('T013','phone',  'billing',      'AMER','enterprise','billing',     48.0, 18, TRUE,  -0.92, TRUE),
('T014','chat',   'core_platform','EMEA','enterprise','bug',         16.0,  8, TRUE,  -0.60, TRUE),
('T015','phone',  'mobile',       'AMER','business',  'bug',         20.0, 11, TRUE,  -0.75, TRUE),
('T016','email',  'api',          'EMEA','enterprise','performance', 27.0, 13, FALSE, -0.82, TRUE),
('T017','portal', 'billing',      'AMER','enterprise','billing',     38.0, 15, TRUE,  -0.88, TRUE),
('T018','phone',  'core_platform','APAC','enterprise','bug',         24.0, 12, TRUE,  -0.71, TRUE),
('T019','email',  'mobile',       'AMER','enterprise','performance', 31.0, 14, TRUE,  -0.84, TRUE),
('T020','phone',  'api',          'EMEA','enterprise','bug',         23.0, 11, TRUE,  -0.77, TRUE),
('T021','phone',  'core_platform','AMER','enterprise','bug',         35.0, 16, TRUE,  -0.86, TRUE),
('T022','email',  'billing',      'EMEA','enterprise','billing',     44.0, 17, TRUE,  -0.93, TRUE),
('T023','phone',  'api',          'APAC','enterprise','performance', 29.0, 13, TRUE,  -0.79, TRUE),
('T024','portal', 'mobile',       'AMER','enterprise','bug',         21.0, 10, TRUE,  -0.74, TRUE),
('T025','phone',  'core_platform','EMEA','enterprise','performance', 32.0, 14, FALSE, -0.83, TRUE),
('T026','email',  'api',          'AMER','enterprise','bug',         17.0,  9, TRUE,  -0.67, TRUE),
('T027','phone',  'billing',      'APAC','enterprise','billing',     40.0, 15, TRUE,  -0.89, TRUE),
('T028','portal', 'core_platform','EMEA','enterprise','bug',         25.0, 11, TRUE,  -0.73, TRUE),
('T029','phone',  'mobile',       'AMER','enterprise','performance', 34.0, 15, TRUE,  -0.87, TRUE),
('T030','email',  'api',          'EMEA','enterprise','bug',         22.5, 10, FALSE, -0.71, TRUE),
('T031','phone',  'core_platform','AMER','business',  'bug',         18.0, 10, TRUE,  -0.64, TRUE),
('T032','email',  'billing',      'EMEA','business',  'billing',     26.0, 12, TRUE,  -0.70, TRUE),
('T033','phone',  'api',          'APAC','enterprise','performance', 37.0, 15, TRUE,  -0.85, TRUE),
('T034','portal', 'mobile',       'AMER','enterprise','bug',         28.5, 13, TRUE,  -0.76, TRUE),
('T035','phone',  'core_platform','EMEA','enterprise','performance', 39.0, 16, FALSE, -0.88, TRUE),
('T036','email',  'api',          'AMER','enterprise','bug',         19.5,  9, TRUE,  -0.69, TRUE),
('T037','phone',  'billing',      'APAC','enterprise','billing',     45.0, 17, TRUE,  -0.91, TRUE),
('T038','portal', 'core_platform','EMEA','enterprise','bug',         23.5, 11, TRUE,  -0.72, TRUE),
('T039','phone',  'mobile',       'AMER','enterprise','performance', 31.5, 14, TRUE,  -0.84, TRUE),
('T040','email',  'api',          'EMEA','enterprise','bug',         20.5, 10, FALSE, -0.70, TRUE),

-- ── ESCALATED = FALSE (40 rows) ──────────────────────────────
-- Clear signals: low response_time, few replies, NOT reopened, positive sentiment
('T041','chat',   'core_platform','AMER','enterprise','bug',          2.5,  3, FALSE,  0.42, FALSE),
('T042','portal', 'billing',      'EMEA','enterprise','billing',      1.0,  2, FALSE,  0.65, FALSE),
('T043','email',  'api',          'APAC','enterprise','feature_req',  4.0,  4, FALSE,  0.30, FALSE),
('T044','chat',   'mobile',       'AMER','enterprise','access',       1.5,  2, FALSE,  0.55, FALSE),
('T045','portal', 'core_platform','EMEA','enterprise','bug',          3.0,  3, FALSE,  0.40, FALSE),
('T046','email',  'api',          'AMER','enterprise','performance',  5.0,  5, FALSE,  0.25, FALSE),
('T047','chat',   'billing',      'APAC','enterprise','billing',      2.0,  2, FALSE,  0.60, FALSE),
('T048','portal', 'mobile',       'AMER','enterprise','bug',          3.5,  4, FALSE,  0.35, FALSE),
('T049','email',  'core_platform','EMEA','enterprise','feature_req',  6.0,  5, FALSE,  0.22, FALSE),
('T050','chat',   'api',          'AMER','enterprise','access',       1.0,  1, FALSE,  0.70, FALSE),
('T051','email',  'core_platform','AMER','business',  'bug',          4.5,  4, FALSE,  0.38, FALSE),
('T052','portal', 'api',          'EMEA','business',  'performance',  3.0,  3, FALSE,  0.44, FALSE),
('T053','chat',   'billing',      'AMER','business',  'billing',      2.0,  2, FALSE,  0.50, FALSE),
('T054','email',  'mobile',       'APAC','business',  'bug',          5.0,  4, FALSE,  0.28, FALSE),
('T055','portal', 'core_platform','EMEA','business',  'feature_req',  4.0,  3, FALSE,  0.45, FALSE),
('T056','chat',   'api',          'AMER','business',  'access',       1.5,  2, FALSE,  0.62, FALSE),
('T057','email',  'billing',      'EMEA','business',  'billing',      3.5,  3, FALSE,  0.36, FALSE),
('T058','portal', 'mobile',       'AMER','business',  'bug',          2.5,  3, FALSE,  0.42, FALSE),
('T059','chat',   'core_platform','APAC','business',  'performance',  3.0,  3, FALSE,  0.48, FALSE),
('T060','email',  'api',          'EMEA','business',  'feature_req',  5.5,  4, FALSE,  0.32, FALSE),
('T061','chat',   'core_platform','AMER','starter',   'how_to',       1.0,  1, FALSE,  0.75, FALSE),
('T062','portal', 'billing',      'EMEA','starter',   'billing',      2.0,  2, FALSE,  0.68, FALSE),
('T063','email',  'api',          'APAC','starter',   'feature_req',  3.5,  3, FALSE,  0.55, FALSE),
('T064','chat',   'mobile',       'AMER','starter',   'bug',          2.5,  3, FALSE,  0.40, FALSE),
('T065','portal', 'core_platform','EMEA','starter',   'access',       1.5,  2, FALSE,  0.62, FALSE),
('T066','email',  'api',          'AMER','starter',   'performance',  4.0,  3, FALSE,  0.35, FALSE),
('T067','chat',   'billing',      'APAC','starter',   'billing',      2.0,  2, FALSE,  0.58, FALSE),
('T068','portal', 'mobile',       'AMER','starter',   'bug',          3.0,  3, FALSE,  0.44, FALSE),
('T069','email',  'core_platform','EMEA','starter',   'feature_req',  4.5,  4, FALSE,  0.30, FALSE),
('T070','chat',   'api',          'AMER','starter',   'access',       1.0,  1, FALSE,  0.72, FALSE),
('T071','chat',   'core_platform','AMER','enterprise','bug',          5.5,  5, FALSE,  0.20, FALSE),
('T072','portal', 'billing',      'EMEA','enterprise','billing',      4.0,  4, FALSE,  0.32, FALSE),
('T073','email',  'api',          'APAC','enterprise','feature_req',  7.0,  5, FALSE,  0.18, FALSE),
('T074','chat',   'mobile',       'AMER','enterprise','access',       2.0,  2, FALSE,  0.58, FALSE),
('T075','portal', 'core_platform','EMEA','enterprise','bug',          6.0,  5, FALSE,  0.24, FALSE),
('T076','email',  'api',          'AMER','enterprise','performance',  8.0,  6, FALSE,  0.15, FALSE),
('T077','chat',   'billing',      'APAC','enterprise','billing',      3.0,  3, FALSE,  0.52, FALSE),
('T078','portal', 'mobile',       'AMER','enterprise','bug',          5.0,  4, FALSE,  0.28, FALSE),
('T079','email',  'core_platform','EMEA','enterprise','feature_req',  9.0,  6, FALSE,  0.12, FALSE),
('T080','chat',   'api',          'AMER','enterprise','access',       1.5,  1, FALSE,  0.68, FALSE);


-- ============================================================
--  STEP 2 — New tickets with CLEAR mixed signals
--  N001,N003,N005,N007,N009 → should be HIGH RISK (escalate)
--  N002,N004,N006,N008,N010 → should be LOW RISK (resolve)
-- ============================================================

CREATE OR REPLACE TABLE SUPPORT_DB.PUBLIC.TICKET_NEW (
  ticket_id         VARCHAR,
  channel           VARCHAR,
  product           VARCHAR,
  region            VARCHAR,
  customer_tier     VARCHAR,
  issue_category    VARCHAR,
  response_time_hrs FLOAT,
  num_replies       NUMBER,
  reopened          BOOLEAN,
  sentiment_score   FLOAT
);

INSERT INTO SUPPORT_DB.PUBLIC.TICKET_NEW VALUES
-- HIGH RISK: enterprise, high response_time, many replies, very negative sentiment
('N001','phone',  'core_platform','AMER','enterprise','bug',         32.0, 14, TRUE,  -0.88),
('N003','phone',  'api',          'APAC','enterprise','performance', 40.0, 16, TRUE,  -0.91),
('N005','phone',  'billing',      'EMEA','enterprise','billing',     45.0, 17, TRUE,  -0.93),
('N007','email',  'core_platform','EMEA','enterprise','bug',         26.0, 12, TRUE,  -0.80),
('N009','phone',  'mobile',       'AMER','enterprise','performance', 38.0, 15, TRUE,  -0.87),
('N011','phone',  'api',          'AMER','enterprise','bug',         35.0, 14, TRUE,  -0.85),
('N013','email',  'billing',      'APAC','enterprise','billing',     42.0, 16, TRUE,  -0.90),

-- MEDIUM RISK: mixed signals — moderate response time, some negative sentiment
('N015','email',  'core_platform','AMER','business',  'bug',         12.0,  7, FALSE, -0.40),
('N016','portal', 'api',          'EMEA','business',  'performance', 10.0,  6, TRUE,  -0.35),
('N017','phone',  'mobile',       'APAC','enterprise','bug',         14.0,  8, FALSE, -0.50),
('N018','email',  'billing',      'AMER','business',  'billing',     11.0,  7, TRUE,  -0.30),
('N019','chat',   'core_platform','EMEA','enterprise','performance',  9.0,  6, FALSE, -0.42),
('N020','portal', 'api',          'AMER','business',  'bug',         13.0,  7, TRUE,  -0.38),

-- LOW RISK: starter/business, low response_time, few replies, positive sentiment
('N002','chat',   'billing',      'EMEA','starter',   'billing',      1.5,  2, FALSE,  0.62),
('N004','portal', 'mobile',       'AMER','business',  'feature_req',  3.5,  3, FALSE,  0.45),
('N006','chat',   'core_platform','AMER','starter',   'access',       1.0,  1, FALSE,  0.70),
('N008','portal', 'api',          'APAC','business',  'feature_req',  4.0,  3, FALSE,  0.38),
('N010','chat',   'billing',      'EMEA','starter',   'billing',      2.0,  2, FALSE,  0.55),
('N012','chat',   'mobile',       'AMER','starter',   'how_to',       1.0,  1, FALSE,  0.75),
('N014','portal', 'core_platform','EMEA','starter',   'access',       2.5,  2, FALSE,  0.60);


-- ============================================================
--  STEP 3 — Recreate view & retrain model
-- ============================================================

CREATE OR REPLACE VIEW SUPPORT_DB.PUBLIC.V_BINARY_TRAIN AS
  SELECT channel, product, region, customer_tier,
         issue_category, response_time_hrs, num_replies,
         reopened, sentiment_score, escalated
  FROM SUPPORT_DB.PUBLIC.TICKET_TRAINING;

-- Drop old model and retrain on balanced data
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION SUPPORT_DB.PUBLIC.ESCALATION_MODEL (
  INPUT_DATA     => SYSTEM$REFERENCE('VIEW', 'SUPPORT_DB.PUBLIC.V_BINARY_TRAIN'),
  TARGET_COLNAME => 'ESCALATED'
);


-- ============================================================
--  STEP 4 — Predict with lower, realistic thresholds
--  HIGH   > 0.55  (was 0.80 — too strict)
--  MEDIUM > 0.35  (was 0.50 — too strict)
-- ============================================================

SELECT
  ticket_id,
  channel,
  customer_tier,
  issue_category,
  response_time_hrs,
  sentiment_score,
  SUPPORT_DB.PUBLIC.ESCALATION_MODEL!PREDICT(INPUT_DATA => {*}):class::VARCHAR
    AS will_escalate,
  ROUND(SUPPORT_DB.PUBLIC.ESCALATION_MODEL!PREDICT(INPUT_DATA => {*}):"probability"::OBJECT:"True"::FLOAT  * 100, 1)
    AS escalation_prob_pct,
  ROUND(SUPPORT_DB.PUBLIC.ESCALATION_MODEL!PREDICT(INPUT_DATA => {*}):"probability"::OBJECT:"False"::FLOAT * 100, 1)
    AS resolution_prob_pct,
  CASE
    WHEN SUPPORT_DB.PUBLIC.ESCALATION_MODEL!PREDICT(INPUT_DATA => {*}):"probability"::OBJECT:"True"::FLOAT > 0.55
    THEN 'HIGH RISK'
    WHEN SUPPORT_DB.PUBLIC.ESCALATION_MODEL!PREDICT(INPUT_DATA => {*}):"probability"::OBJECT:"True"::FLOAT > 0.35
    THEN 'MEDIUM RISK'
    ELSE 'LOW RISK'
  END AS risk_level
FROM SUPPORT_DB.PUBLIC.TICKET_NEW
ORDER BY escalation_prob_pct DESC;


-- ============================================================
--  STEP 5 — Evaluate the retrained model
-- ============================================================

CALL SUPPORT_DB.PUBLIC.ESCALATION_MODEL!SHOW_EVALUATION_METRICS();
CALL SUPPORT_DB.PUBLIC.ESCALATION_MODEL!SHOW_GLOBAL_EVALUATION_METRICS();
CALL SUPPORT_DB.PUBLIC.ESCALATION_MODEL!SHOW_CONFUSION_MATRIX();
CALL SUPPORT_DB.PUBLIC.ESCALATION_MODEL!SHOW_FEATURE_IMPORTANCE();


-- ============================================================
--  STEP 6 — Save results
-- ============================================================

CREATE OR REPLACE TABLE SUPPORT_DB.PUBLIC.ESCALATION_PREDICTIONS AS
SELECT
  ticket_id,
  channel,
  customer_tier,
  issue_category,
  response_time_hrs,
  sentiment_score,
  SUPPORT_DB.PUBLIC.ESCALATION_MODEL!PREDICT(INPUT_DATA => {*}):class::VARCHAR
    AS will_escalate,
  ROUND(SUPPORT_DB.PUBLIC.ESCALATION_MODEL!PREDICT(INPUT_DATA => {*}):"probability"::OBJECT:"True"::FLOAT * 100, 1)
    AS escalation_prob_pct,
  CASE
    WHEN SUPPORT_DB.PUBLIC.ESCALATION_MODEL!PREDICT(INPUT_DATA => {*}):"probability"::OBJECT:"True"::FLOAT > 0.55
    THEN 'HIGH'
    WHEN SUPPORT_DB.PUBLIC.ESCALATION_MODEL!PREDICT(INPUT_DATA => {*}):"probability"::OBJECT:"True"::FLOAT > 0.35
    THEN 'MEDIUM'
    ELSE 'LOW'
  END AS risk_level,
  CURRENT_TIMESTAMP AS predicted_at
FROM SUPPORT_DB.PUBLIC.TICKET_NEW;

-- Preview — high risk first
SELECT * FROM SUPPORT_DB.PUBLIC.ESCALATION_PREDICTIONS
ORDER BY escalation_prob_pct DESC;

-- Count by risk level — should now show HIGH, MEDIUM, LOW mix
SELECT risk_level, COUNT(*) AS ticket_count
FROM SUPPORT_DB.PUBLIC.ESCALATION_PREDICTIONS
GROUP BY risk_level
ORDER BY ticket_count DESC;
