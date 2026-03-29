============================================================
Snowflake Cortex Search RAG - Setup SQL
Run this once in a Snowflake Worksheet before starting the app
============================================================

-- 1. Create database & schema
CREATE DATABASE IF NOT EXISTS PDF_RAG_DB;
CREATE SCHEMA IF NOT EXISTS PDF_RAG_DB.DATA;

USE DATABASE PDF_RAG_DB;
USE SCHEMA DATA;

-- 2. Table to store PDF text chunks
CREATE OR REPLACE TABLE PDF_RAG_DB.DATA.DOCS_CHUNKS (
    FILE_NAME   VARCHAR,        -- original PDF filename
    CHUNK_INDEX INT,            -- chunk number within the file
    CHUNK       TEXT,           -- actual text chunk (used for search)
    UPLOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- 3. Cortex Search Service
--    - Indexes the CHUNK column for hybrid semantic + keyword search
--    - TARGET_LAG controls how quickly new rows are indexed (set low for demo)
--    Replace COMPUTE_WH with your warehouse name if different
CREATE OR REPLACE CORTEX SEARCH SERVICE PDF_RAG_DB.DATA.PDF_SEARCH_SERVICE
    ON CHUNK
    ATTRIBUTES FILE_NAME
    WAREHOUSE = COMPUTE_WH
    TARGET_LAG = '1 minute'
    AS (
        SELECT
            CHUNK,
            FILE_NAME
        FROM PDF_RAG_DB.DATA.DOCS_CHUNKS
    );

-- 4. Verify setup
SHOW CORTEX SEARCH SERVICES;
SELECT COUNT(*) AS total_chunks FROM PDF_RAG_DB.DATA.DOCS_CHUNKS;

============================================================
OPTIONAL: Clear all chunks (reset)
TRUNCATE TABLE PDF_RAG_DB.DATA.DOCS_CHUNKS;
============================================================
