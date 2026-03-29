-- ════════════════════════════════════════════════════════════════════
--  SNOWFLAKE CORTEX AGENT — STEP 2
--  Agent with a Custom SQL Tool
--
--  What's new vs Step 1:
--    ✦ A real sample table (products)
--    ✦ A stored procedure as a callable tool
--    ✦ Tool wired into the agent spec
--    ✦ Orchestration instruction to route data questions to the tool
--
--  STANDALONE — run this independently, no Step 1 needed
--  Run order: execute each section top to bottom
-- ════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────
--  SETUP — create everything from scratch (independent of Step 1)
-- ─────────────────────────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS demo_db;
CREATE SCHEMA  IF NOT EXISTS demo_db.agents;

CREATE WAREHOUSE IF NOT EXISTS agent_wh
  WAREHOUSE_SIZE = 'xsmall'
  AUTO_SUSPEND   = 60
  AUTO_RESUME    = TRUE;

USE DATABASE demo_db;
USE SCHEMA   demo_db.agents;



-- ─────────────────────────────────────────────────────────────────
--  SECTION 1 — Sample Data Table
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE TABLE demo_db.agents.products (
    product_id   INT,
    product_name VARCHAR(100),
    category     VARCHAR(50),
    price        DECIMAL(10,2),
    stock_qty    INT,
    region       VARCHAR(50)
);

INSERT INTO demo_db.agents.products VALUES
  (1,  'Snowboard Pro X',     'Sports',   499.99,  120, 'North America'),
  (2,  'Trail Running Shoes', 'Sports',    89.99,  340, 'Europe'),
  (3,  'Yoga Mat Premium',    'Fitness',   45.00,  500, 'Asia'),
  (4,  'Camping Tent 4P',     'Outdoors', 220.00,   80, 'North America'),
  (5,  'Road Bike 21S',       'Sports',   749.99,   55, 'Europe'),
  (6,  'Dumbbell Set 20kg',   'Fitness',  110.00,  200, 'North America'),
  (7,  'Kayak Explorer',      'Outdoors', 599.00,   30, 'Asia'),
  (8,  'Smart Water Bottle',  'Fitness',   35.00, 1000, 'Global'),
  (9,  'Climbing Harness',    'Outdoors',  95.00,  150, 'Europe'),
  (10, 'Soccer Ball Pro',     'Sports',    40.00,  600, 'Global');

-- verify
SELECT * FROM demo_db.agents.products;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 2 — Stored Procedure (the Tool)
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE demo_db.agents.query_products(user_query STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
AS
$$
def run(session, user_query: str) -> str:
    """
    Routes the user question to the right pre-built SQL query.
    Returns results as a formatted plain-text table.
    """
    query = user_query.strip().lower()

    if any(k in query for k in ["top", "expensive", "price", "cost"]):
        sql = """
            SELECT product_name, category, price, region
            FROM demo_db.agents.products
            ORDER BY price DESC
            LIMIT 5
        """
    elif any(k in query for k in ["stock", "inventory", "low", "available"]):
        sql = """
            SELECT product_name, stock_qty, region
            FROM demo_db.agents.products
            ORDER BY stock_qty ASC
            LIMIT 5
        """
    elif any(k in query for k in ["category", "group", "type"]):
        sql = """
            SELECT category,
                   COUNT(*)            AS total_products,
                   ROUND(AVG(price),2) AS avg_price,
                   SUM(stock_qty)      AS total_stock
            FROM demo_db.agents.products
            GROUP BY category
            ORDER BY total_products DESC
        """
    elif any(k in query for k in ["region", "location", "country", "area"]):
        sql = """
            SELECT region,
                   COUNT(*)            AS total_products,
                   ROUND(SUM(price),2) AS total_value
            FROM demo_db.agents.products
            GROUP BY region
            ORDER BY total_value DESC
        """
    else:
        sql = """
            SELECT product_name, category, price, stock_qty, region
            FROM demo_db.agents.products
            ORDER BY product_id
        """

    rows = session.sql(sql).collect()
    if not rows:
        return "No data found."

    headers = list(rows[0].as_dict().keys())
    lines   = [" | ".join(headers), "-" * 60]
    for row in rows:
        lines.append(" | ".join(str(v) for v in row.as_dict().values()))

    return "\n".join(lines)
$$;

-- sanity check — test the procedure directly
CALL demo_db.agents.query_products('show me the most expensive products');
CALL demo_db.agents.query_products('which items have low stock inventory');
CALL demo_db.agents.query_products('breakdown by category');
CALL demo_db.agents.query_products('which regions have the most products');


-- ─────────────────────────────────────────────────────────────────
--  SECTION 3 — Create the Agent (with tool wired in)
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE AGENT demo_db.agents.products_agent
  COMMENT = 'Step 2 — Agent with a custom SQL tool for product data'
FROM SPECIFICATION $$
models:
  orchestration: claude-4-sonnet

orchestration:
  budget:
    seconds: 60
    tokens: 4000

instructions:
  system: >
    You are a helpful product data assistant for a sports and fitness retailer.
    You have access to a product catalog tool. Always use it when the user
    asks about products, prices, stock levels, categories, or regions.
    If the question is general knowledge, answer directly without the tool.
  response: >
    Be concise. When showing data from the tool, summarise the key insight
    in one sentence before presenting the numbers.
  orchestration: >
    For any question about products, pricing, inventory, stock, categories,
    or regions — call the query_products tool.
    For general questions about Snowflake or AI, answer from your own knowledge.
  sample_questions:
    - question: "Which products are the most expensive?"
      answer: "I'll query the product catalog and show you the top 5 by price."
    - question: "Which items are running low on stock?"
      answer: "Let me check current inventory levels for you."
    - question: "Give me a breakdown by product category."
      answer: "I'll group the catalog by category and show counts and averages."
    - question: "Which regions have the most product value?"
      answer: "I'll analyse product distribution and total value by region."

tools:
  - tool_spec:
      type: "custom_tool"
      name: "query_products"
      description: >
        Queries the products table in Snowflake. Use this for any question
        about product names, prices, stock quantities, categories, or regions.
        Pass the user's question as-is so the tool can route to the right query.
      input_schema:
        type: object
        properties:
          user_query:
            type: string
            description: "The user's natural language question about products"
        required:
          - user_query

tool_resources:
  query_products:
    procedure: "demo_db.agents.query_products"
    warehouse: "agent_wh"
$$;

-- ─────────────────────────────────────────────────────────────────
--  SECTION 4 — Call the Agent
-- ─────────────────────────────────────────────────────────────────

-- general question (agent answers from LLM, no tool call)
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.products_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "What is Snowflake Cortex?"}]}')
) AS response;

-- data questions (tool will be called automatically)
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.products_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "Which products are the most expensive?"}]}')
) AS response;

SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.products_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "Which items are running low on stock?"}]}')
) AS response;

SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.products_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "Give me a breakdown by product category."}]}')
) AS response;

SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.products_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "Which regions have the most product value?"}]}')
) AS response;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 5 — Clean Readable Output (extract text only)
-- ─────────────────────────────────────────────────────────────────

SELECT
  response:choices[0]:messages[0]:content::STRING AS answer
FROM (
  SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'demo_db.agents.products_agent',
    PARSE_JSON('{"messages": [{"role": "user", "content": "Which items are running low on stock?"}]}')
  ) AS response
);


-- ════════════════════════════════════════════════════════════════════
--  WHAT CHANGED FROM STEP 1 → STEP 2
-- ════════════════════════════════════════════════════════════════════
--
--  Step 1  →  Pure LLM agent, general knowledge only, no data access
--  Step 2  →  + Real products table
--             + Stored procedure tool (query_products)
--             + Tool wired into agent spec under [tools] + [tool_resources]
--             + Orchestration instruction to route data questions to tool
--             + Budget increased: 60s / 4000 tokens
--
--  NEXT → Step 3: Add Cortex Search for unstructured document Q&A
-- ════════════════════════════════════════════════════════════════════
