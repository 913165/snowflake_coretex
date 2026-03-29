-- ============================================================
--  SNOWFLAKE MCP DEMO SETUP  — Full Script with All Grants
--  Run as ACCOUNTADMIN or SYSADMIN
-- ============================================================

-- !! SET YOUR VALUES HERE !!
SET MY_ROLE      = 'ACCOUNTADMIN';
SET MY_USER      = 'TINUMISTRY';
SET MY_WAREHOUSE = 'COMPUTE_WH';


-- ============================================================
-- STEP 1 — WAREHOUSE GRANTS
-- ============================================================
USE ROLE ACCOUNTADMIN;

GRANT USAGE ON WAREHOUSE IDENTIFIER($MY_WAREHOUSE) TO ROLE IDENTIFIER($MY_ROLE);


-- ============================================================
-- STEP 2 — DATABASE & SCHEMA
-- ============================================================
USE ROLE IDENTIFIER($MY_ROLE);

CREATE DATABASE IF NOT EXISTS PRODUCT_DB;
USE DATABASE PRODUCT_DB;

CREATE SCHEMA IF NOT EXISTS PRODUCT_SCHEMA;
USE SCHEMA PRODUCT_SCHEMA;

USE WAREHOUSE IDENTIFIER($MY_WAREHOUSE);


-- ============================================================
-- STEP 3 — PRODUCTS TABLE
-- ============================================================
CREATE OR REPLACE TABLE PRODUCTS (
    PRODUCT_ID      NUMBER        PRIMARY KEY,
    PRODUCT_NAME    VARCHAR(200),
    CATEGORY        VARCHAR(100),
    PRICE           NUMBER(10,2),
    STOCK_QTY       NUMBER,
    DESCRIPTION     VARCHAR(1000)
);


-- ============================================================
-- STEP 4 — INSERT 20 PRODUCTS
-- ============================================================
INSERT INTO PRODUCTS VALUES
 (1,  'Laptop Pro 15',       'Electronics',  1299.99, 45,  'High-performance laptop with 15-inch display and 16GB RAM'),
 (2,  'Wireless Mouse',      'Electronics',    29.99, 200, 'Ergonomic wireless mouse with long battery life'),
 (3,  'USB-C Hub 7-Port',    'Electronics',    49.99, 150, 'Multi-port USB-C hub with HDMI and SD card slot'),
 (4,  'Mechanical Keyboard', 'Electronics',    89.99, 80,  'Tactile mechanical keyboard with RGB backlight'),
 (5,  'Monitor 27" 4K',      'Electronics',   399.99, 30,  'Ultra HD 4K monitor with 60Hz refresh rate'),
 (6,  'Running Shoes X1',    'Footwear',       79.99, 120, 'Lightweight running shoes with cushioned sole'),
 (7,  'Leather Sneakers',    'Footwear',       99.99, 90,  'Classic leather sneakers suitable for casual wear'),
 (8,  'Trail Boots Pro',     'Footwear',      139.99, 60,  'Waterproof trail boots for outdoor hiking'),
 (9,  'Sports Sandals',      'Footwear',       39.99, 180, 'Comfortable sports sandals with arch support'),
 (10, 'Slip-on Loafers',     'Footwear',       59.99, 110, 'Easy slip-on loafers great for office and casual'),
 (11, 'Office Chair Ergon',  'Furniture',     299.99, 25,  'Fully adjustable ergonomic office chair with lumbar support'),
 (12, 'Standing Desk 60"',   'Furniture',     499.99, 15,  'Electric height-adjustable standing desk with memory presets'),
 (13, 'Bookshelf 5-Tier',    'Furniture',     129.99, 40,  'Modern 5-tier wooden bookshelf with metal frame'),
 (14, 'Desk Lamp LED',       'Furniture',      34.99, 200, 'Dimmable LED desk lamp with USB charging port'),
 (15, 'Monitor Stand',       'Furniture',      44.99, 100, 'Adjustable monitor stand with storage drawer'),
 (16, 'Yoga Mat Premium',    'Sports',         29.99, 300, 'Non-slip premium yoga mat 6mm thick'),
 (17, 'Dumbbell Set 20kg',   'Sports',         89.99, 50,  'Adjustable dumbbell set up to 20kg per dumbbell'),
 (18, 'Resistance Bands',    'Sports',         19.99, 400, 'Set of 5 resistance bands with different tension levels'),
 (19, 'Water Bottle 1L',     'Sports',         24.99, 250, 'Insulated stainless steel water bottle keeps cold 24hr'),
 (20, 'Foam Roller',         'Sports',         22.99, 180, 'High-density foam roller for muscle recovery');

SELECT COUNT(*) AS TOTAL_PRODUCTS FROM PRODUCTS;   -- should be 20


-- ============================================================
-- STEP 5 — CORTEX SEARCH SERVICE
-- ============================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE PRODUCT_SEARCH_SVC
    ON DESCRIPTION
    ATTRIBUTES PRODUCT_NAME, CATEGORY, PRICE, STOCK_QTY
    WAREHOUSE = IDENTIFIER($MY_WAREHOUSE)
    TARGET_LAG = '1 hour'
    AS
        SELECT
            PRODUCT_ID,
            PRODUCT_NAME,
            CATEGORY,
            PRICE,
            STOCK_QTY,
            DESCRIPTION
        FROM PRODUCTS;


-- ============================================================
-- STEP 6 — SEMANTIC VIEW
-- ============================================================
CREATE OR REPLACE SEMANTIC VIEW PRODUCT_SEMANTIC_VIEW
    TABLES (
        BASE_TABLE AS PRODUCTS
    )
    DIMENSIONS (
        BASE_TABLE.PRODUCT_ID,
        BASE_TABLE.PRODUCT_NAME,
        BASE_TABLE.CATEGORY
    )
    METRICS (
        AVG_PRICE     AS AVG(BASE_TABLE.PRICE),
        TOTAL_STOCK   AS SUM(BASE_TABLE.STOCK_QTY),
        PRODUCT_COUNT AS COUNT(BASE_TABLE.PRODUCT_ID)
    )
    COMMENT = 'Semantic view for product pricing and inventory analytics';


-- ============================================================
-- STEP 7 — MCP SERVER
-- ============================================================
CREATE OR REPLACE MCP SERVER PRODUCT_MCP_SERVER
  FROM SPECIFICATION $$
    tools:
      - name: "product-search"
        type: "CORTEX_SEARCH_SERVICE_QUERY"
        identifier: "PRODUCT_DB.PRODUCT_SCHEMA.PRODUCT_SEARCH_SVC"
        description: "Semantic search over all products by name and description"
        title: "Product Search"

      - name: "product-analytics"
        type: "CORTEX_ANALYST_MESSAGE"
        identifier: "PRODUCT_DB.PRODUCT_SCHEMA.PRODUCT_SEMANTIC_VIEW"
        description: "Ask natural language questions about product pricing, stock, and categories"
        title: "Product Analytics"
  $$;


-- ============================================================
-- STEP 8 — ALL GRANTS
-- ============================================================
USE ROLE ACCOUNTADMIN;

-- ── Database & Schema ────────────────────────────────────────
GRANT USAGE ON DATABASE PRODUCT_DB                TO ROLE IDENTIFIER($MY_ROLE);
GRANT USAGE ON SCHEMA   PRODUCT_DB.PRODUCT_SCHEMA TO ROLE IDENTIFIER($MY_ROLE);

-- ── Future objects auto-grant ────────────────────────────────
GRANT ALL PRIVILEGES ON FUTURE TABLES        IN SCHEMA PRODUCT_DB.PRODUCT_SCHEMA TO ROLE IDENTIFIER($MY_ROLE);
GRANT ALL PRIVILEGES ON FUTURE VIEWS         IN SCHEMA PRODUCT_DB.PRODUCT_SCHEMA TO ROLE IDENTIFIER($MY_ROLE);
GRANT ALL PRIVILEGES ON FUTURE SEMANTIC VIEWS IN SCHEMA PRODUCT_DB.PRODUCT_SCHEMA TO ROLE IDENTIFIER($MY_ROLE);

-- ── Table ────────────────────────────────────────────────────
GRANT SELECT  ON TABLE PRODUCT_DB.PRODUCT_SCHEMA.PRODUCTS TO ROLE IDENTIFIER($MY_ROLE);

-- ── Cortex Search Service ────────────────────────────────────
GRANT USAGE   ON CORTEX SEARCH SERVICE PRODUCT_DB.PRODUCT_SCHEMA.PRODUCT_SEARCH_SVC TO ROLE IDENTIFIER($MY_ROLE);

-- ── Semantic View ────────────────────────────────────────────
GRANT SELECT  ON SEMANTIC VIEW PRODUCT_DB.PRODUCT_SCHEMA.PRODUCT_SEMANTIC_VIEW TO ROLE IDENTIFIER($MY_ROLE);

-- ── MCP Server ───────────────────────────────────────────────
GRANT USAGE   ON MCP SERVER PRODUCT_DB.PRODUCT_SCHEMA.PRODUCT_MCP_SERVER TO ROLE IDENTIFIER($MY_ROLE);

-- ── Cortex AI Functions (required for COMPLETE, SEARCH, ANALYST) ─
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE IDENTIFIER($MY_ROLE);

-- ── Warehouse ────────────────────────────────────────────────
GRANT USAGE, OPERATE ON WAREHOUSE IDENTIFIER($MY_WAREHOUSE) TO ROLE IDENTIFIER($MY_ROLE);

-- ── Assign role to user ──────────────────────────────────────
GRANT ROLE IDENTIFIER($MY_ROLE) TO USER IDENTIFIER($MY_USER);


-- ============================================================
-- STEP 9 — VERIFY EVERYTHING
-- ============================================================
USE ROLE IDENTIFIER($MY_ROLE);
USE DATABASE PRODUCT_DB;
USE SCHEMA   PRODUCT_SCHEMA;
USE WAREHOUSE IDENTIFIER($MY_WAREHOUSE);

-- Check table
SELECT COUNT(*) AS TOTAL_PRODUCTS FROM PRODUCTS;

-- Check objects
SHOW CORTEX SEARCH SERVICES IN SCHEMA PRODUCT_DB.PRODUCT_SCHEMA;
SHOW SEMANTIC VIEWS          IN SCHEMA PRODUCT_DB.PRODUCT_SCHEMA;
SHOW MCP SERVERS             IN SCHEMA PRODUCT_DB.PRODUCT_SCHEMA;

-- Inspect MCP server tools
DESCRIBE MCP SERVER PRODUCT_DB.PRODUCT_SCHEMA.PRODUCT_MCP_SERVER;


-- ============================================================
-- STEP 10 — DEMO: NATURAL LANGUAGE QUERIES
--           Once MCP server is connected to Claude, try these
-- ============================================================

-- ── Uses: product-search  (Cortex Search Service) ────────────
--
--   Query 1: "Find me all products related to working from home"
--
--   Query 2: "Search for sports and fitness products under $30"
--
-- ── Uses: product-analytics  (Cortex Analyst + Semantic View) ─
--
--   Query 3: "What is the average price of products in each category?"
--
--   Query 4: "Which category has the highest total stock quantity?"
--
-- ============================================================
