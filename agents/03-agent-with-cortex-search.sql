-- ════════════════════════════════════════════════════════════════════
--  SNOWFLAKE CORTEX AGENT — STEP 3
--  Agent with Cortex Search (Unstructured Document Q&A)
--
--  What's new vs Step 2:
--    ✦ A documents table storing product FAQs and policy text
--    ✦ A Cortex Search Service built on top of that table
--    ✦ Cortex Search wired into the agent as a search tool
--    ✦ Agent now handles both data questions (SQL tool)
--      and document questions (Cortex Search)
--
--  STANDALONE — run this independently, no prior steps needed
--  Run order: execute each section top to bottom
-- ════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────
--  SETUP — create everything from scratch
-- ─────────────────────────────────────────────────────────────────

CREATE DATABASE  IF NOT EXISTS demo_db;
CREATE SCHEMA    IF NOT EXISTS demo_db.agents;

CREATE WAREHOUSE IF NOT EXISTS agent_wh
  WAREHOUSE_SIZE = 'xsmall'
  AUTO_SUSPEND   = 60
  AUTO_RESUME    = TRUE;

USE DATABASE demo_db;
USE SCHEMA   demo_db.agents;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 1 — Product Table (same as Step 2)
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


-- ─────────────────────────────────────────────────────────────────
--  SECTION 2 — Documents Table (unstructured text)
--  This is what Cortex Search will index and retrieve from
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE TABLE demo_db.agents.product_docs (
    doc_id       INT,
    doc_title    VARCHAR(200),
    category     VARCHAR(50),
    doc_text     TEXT
);

INSERT INTO demo_db.agents.product_docs VALUES

(1, 'Return Policy', 'Policy',
'Our return policy allows customers to return any product within 30 days of purchase.
Items must be in original condition with tags attached. Sports equipment that has been
used outdoors is not eligible for return unless it is defective. To initiate a return,
contact our support team with your order number and reason for return. Refunds are
processed within 5-7 business days after we receive the item.'),

(2, 'Shipping Information', 'Policy',
'We offer free standard shipping on all orders over $100. Standard shipping takes
5-7 business days. Express shipping (2-3 business days) is available for an
additional fee of $15. Orders placed before 2 PM EST are processed the same day.
We currently ship to North America, Europe, and select countries in Asia.
International orders may be subject to customs duties and taxes.'),

(3, 'Snowboard Pro X — Product Guide', 'Sports',
'The Snowboard Pro X is designed for intermediate to advanced riders. It features
a directional twin shape optimized for both groomed runs and powder. The board uses
a carbon fiber core which keeps it lightweight at 2.8 kg while maintaining stiffness
for high-speed stability. Recommended boot size range is EU 38-46. The binding
inserts follow the 4x4 standard, compatible with most major binding brands.
Maintenance tip: wax the base every 5-8 days of riding for best performance.'),

(4, 'Camping Tent 4P — Setup Guide', 'Outdoors',
'The Camping Tent 4P can be set up by two people in approximately 15 minutes.
Start by laying out the footprint, then assemble the two main poles by connecting
the segments. Thread the poles through the pole sleeves on the tent body, then
clip the tent body to the poles. Insert the pole tips into the corner grommets.
Attach the rainfly over the tent and stake out all corners and guy lines.
The tent is rated for 3-season use and can handle winds up to 60 km/h.
Always dry the tent before storing to prevent mould.'),

(5, 'Warranty Policy', 'Policy',
'All products come with a standard 1-year manufacturer warranty covering defects
in materials and workmanship. Outdoor and sports equipment has an extended 2-year
warranty. Warranty does not cover normal wear and tear, accidental damage, or
damage caused by misuse. To make a warranty claim, contact our support team with
proof of purchase and a description of the defect. We will either repair or replace
the item at our discretion. Warranty claims are typically processed within 10 business days.'),

(6, 'Road Bike 21S — Maintenance Guide', 'Sports',
'The Road Bike 21S requires regular maintenance to ensure safe and smooth riding.
Check tyre pressure before every ride — recommended pressure is 90-110 PSI.
Lubricate the chain every 200 km or after riding in wet conditions. Inspect brake
pads monthly and replace when thickness falls below 2 mm. The 21-speed Shimano
gear system should be indexed every 3-6 months. For full service including wheel
truing and cable replacement, visit a certified bike shop annually. Store the bike
indoors away from moisture to prevent rust on the frame and components.'),

(7, 'Frequently Asked Questions', 'General',
'Q: Can I return a product I bought on sale?
A: Yes, sale items follow the same 30-day return policy as full-price items.
Q: Do you offer price matching?
A: We offer price matching within 14 days of purchase if you find the same item cheaper.
Q: How do I track my order?
A: Once your order ships, you will receive an email with a tracking number.
Q: Are your outdoor products waterproof?
A: The Camping Tent 4P and Kayak Explorer are fully waterproof. The Climbing Harness
is water-resistant. Always check the individual product specifications.
Q: Do you ship to my country?
A: We ship to North America, Europe, and select Asian countries. Check checkout for eligibility.');

-- verify
SELECT doc_id, doc_title, category FROM demo_db.agents.product_docs;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 3 — Cortex Search Service
--  Indexes the documents table for semantic + keyword search
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE CORTEX SEARCH SERVICE demo_db.agents.product_search
  ON doc_text
  ATTRIBUTES doc_title, category
  WAREHOUSE = agent_wh
  TARGET_LAG = '1 hour'
AS (
  SELECT
    doc_id,
    doc_title,
    category,
    doc_text
  FROM demo_db.agents.product_docs
);

-- verify the search service was created
SHOW CORTEX SEARCH SERVICES IN SCHEMA demo_db.agents;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 4 — SQL Tool Procedure (same as Step 2)
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
    query = user_query.strip().lower()

    if any(k in query for k in ["top", "expensive", "price", "cost"]):
        sql = """
            SELECT product_name, category, price, region
            FROM demo_db.agents.products
            ORDER BY price DESC LIMIT 5
        """
    elif any(k in query for k in ["stock", "inventory", "low", "available"]):
        sql = """
            SELECT product_name, stock_qty, region
            FROM demo_db.agents.products
            ORDER BY stock_qty ASC LIMIT 5
        """
    elif any(k in query for k in ["category", "group", "type"]):
        sql = """
            SELECT category,
                   COUNT(*)            AS total_products,
                   ROUND(AVG(price),2) AS avg_price,
                   SUM(stock_qty)      AS total_stock
            FROM demo_db.agents.products
            GROUP BY category ORDER BY total_products DESC
        """
    elif any(k in query for k in ["region", "location", "area"]):
        sql = """
            SELECT region,
                   COUNT(*)            AS total_products,
                   ROUND(SUM(price),2) AS total_value
            FROM demo_db.agents.products
            GROUP BY region ORDER BY total_value DESC
        """
    else:
        sql = """
            SELECT product_name, category, price, stock_qty, region
            FROM demo_db.agents.products ORDER BY product_id
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


-- ─────────────────────────────────────────────────────────────────
--  SECTION 5 — Create the Agent (SQL tool + Cortex Search)
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE AGENT demo_db.agents.search_agent
  COMMENT = 'Step 3 — Agent with SQL tool and Cortex Search for documents'
FROM SPECIFICATION $$
models:
  orchestration: claude-4-sonnet

orchestration:
  budget:
    seconds: 60
    tokens: 6000

instructions:
  system: >
    You are a helpful assistant for a sports and fitness retailer.
    You have two tools available:
    1. query_products — use this for questions about product prices,
       stock levels, categories, or regions.
    2. product_search — use this for questions about policies, guides,
       FAQs, warranties, shipping, or returns.
    Always use the appropriate tool before answering. Only answer from
    your own knowledge if neither tool is relevant.
  response: >
    Be clear and concise. When answering from a document, mention
    the source document title so the user knows where the answer came from.
  orchestration: >
    Route structured data questions (prices, stock, categories, regions)
    to query_products. Route unstructured questions (policies, guides,
    FAQs, warranties, returns, shipping, setup instructions) to
    product_search. Use both tools together if the question spans
    both structured and unstructured data.

sample_questions:
  - question: "What is your return policy?"
    answer: "I'll search our policy documents and summarise the return conditions."
  - question: "Which products are the most expensive?"
    answer: "I'll query the product catalog and show you the top 5 by price."
  - question: "How do I set up the Camping Tent 4P?"
    answer: "I'll find the setup guide for the Camping Tent 4P in our documents."
  - question: "Which items are low on stock?"
    answer: "Let me check current inventory levels for you."
  - question: "What does the warranty cover?"
    answer: "I'll search our warranty policy document and summarise the key points."

tools:
  - tool_spec:
      type: "user_defined"
      name: "query_products"
      description: >
        Queries the products table for structured data — prices, stock
        quantities, categories, and regions. Use for any numeric or
        inventory-related questions about the product catalog.
      input_schema:
        type: object
        properties:
          user_query:
            type: string
            description: "The user's natural language question about products"
        required:
          - user_query

  - tool_spec:
      type: "cortex_search"
      name: "product_search"
      description: >
        Searches product documentation, policy documents, setup guides,
        FAQs, and warranty information. Use for any question about
        policies, instructions, or product details not found in the catalog.

tool_resources:
  query_products:
    procedure: "demo_db.agents.query_products"
    warehouse:  "agent_wh"
  product_search:
    name: "demo_db.agents.product_search"
    max_results: 3
$$;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 6 — Call the Agent
-- ─────────────────────────────────────────────────────────────────

-- document question → Cortex Search will be used
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.search_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "What is your return policy?"}]}')
) AS response;

-- document question → setup guide
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.search_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "How do I set up the Camping Tent 4P?"}]}')
) AS response;

-- document question → warranty
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.search_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "What does the warranty cover and for how long?"}]}')
) AS response;

-- structured data question → SQL tool will be used
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.search_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "Which products are the most expensive?"}]}')
) AS response;

-- mixed question → agent uses both tools
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'demo_db.agents.search_agent',
  PARSE_JSON('{"messages": [{"role": "user", "content": "Which outdoor products do you sell and how do I maintain the Road Bike?"}]}')
) AS response;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 7 — Clean Readable Output
-- ─────────────────────────────────────────────────────────────────

SELECT
  response:choices[0]:messages[0]:content::STRING AS answer
FROM (
  SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'demo_db.agents.search_agent',
    PARSE_JSON('{"messages": [{"role": "user", "content": "What is your shipping policy?"}]}')
  ) AS response
);


-- ════════════════════════════════════════════════════════════════════
--  WHAT CHANGED FROM STEP 2 → STEP 3
-- ════════════════════════════════════════════════════════════════════
--
--  Step 2  →  Agent + structured data via SQL stored procedure tool
--  Step 3  →  + Documents table with FAQs, policies, and guides
--             + Cortex Search Service indexing those documents
--             + Cortex Search wired in as a second tool
--             + Agent now routes between SQL tool and Search tool
--             + Budget increased: 60s / 6000 tokens
--
--  NEXT → Step 4: Add Cortex Analyst (semantic view + text-to-SQL)
-- ════════════════════════════════════════════════════════════════════
