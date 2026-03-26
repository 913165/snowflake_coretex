Got it 👍 — you want a **clean Markdown file** where **every prompt is wrapped in triple backticks** so you can directly copy/paste into your course material.

Here is the **updated version (proper MD format)**:

---

# MASTER PROMPT (Create Full Project)

```text
Create a complete Snowflake demo project for an Ecommerce system demonstrating Bronze, Silver and Gold data layers.

Use ONE database named ECOMMERCE_DB.

Create schemas for each layer:

BRONZE_USERS_SCHEMA
SILVER_USERS_SCHEMA
GOLD_USERS_SCHEMA

BRONZE_CATALOG_SCHEMA
SILVER_CATALOG_SCHEMA
GOLD_CATALOG_SCHEMA

BRONZE_ORDERS_SCHEMA
SILVER_ORDERS_SCHEMA
GOLD_ORDERS_SCHEMA

BRONZE_SHOPPING_SCHEMA
SILVER_SHOPPING_SCHEMA
GOLD_SHOPPING_SCHEMA

BRONZE_SOCIAL_SCHEMA
SILVER_SOCIAL_SCHEMA
GOLD_SOCIAL_SCHEMA

Requirements:
1. Bronze layer should contain raw tables with duplicates and inconsistent formats
2. Silver layer should contain cleaned and normalized tables
3. Gold layer should contain aggregated business tables
4. Provide CREATE TABLE statements
5. Provide sample INSERT statements
6. Provide transformation SQL from bronze to silver
7. Provide transformation SQL from silver to gold
8. Keep data simple for demo purposes
9. Use realistic ecommerce fields
```

---

# STEP 1 PROMPT — Create Database and Schemas

```text
Generate Snowflake SQL to create database ECOMMERCE_DB and all schemas:

BRONZE_USERS_SCHEMA
SILVER_USERS_SCHEMA
GOLD_USERS_SCHEMA

BRONZE_CATALOG_SCHEMA
SILVER_CATALOG_SCHEMA
GOLD_CATALOG_SCHEMA

BRONZE_ORDERS_SCHEMA
SILVER_ORDERS_SCHEMA
GOLD_ORDERS_SCHEMA

BRONZE_SHOPPING_SCHEMA
SILVER_SHOPPING_SCHEMA
GOLD_SHOPPING_SCHEMA

BRONZE_SOCIAL_SCHEMA
SILVER_SOCIAL_SCHEMA
GOLD_SOCIAL_SCHEMA
```

---

# STEP 2 PROMPT — Bronze Tables (Raw Data)

```text
Create Bronze layer tables for Ecommerce system with raw messy structure.

Include duplicates and inconsistent formats.

Tables:

BRONZE_USERS_SCHEMA:
users_raw
addresses_raw

BRONZE_CATALOG_SCHEMA:
categories_raw
products_raw
product_variants_raw
product_images_raw

BRONZE_ORDERS_SCHEMA:
orders_raw
order_items_raw
payments_raw

BRONZE_SHOPPING_SCHEMA:
carts_raw
cart_items_raw
coupons_raw

BRONZE_SOCIAL_SCHEMA:
reviews_raw

Provide CREATE TABLE SQL.
```

---

# STEP 3 PROMPT — Insert Raw Data

```text
Insert sample data into bronze tables with following issues:

duplicate users
duplicate products
null values
inconsistent email formats
inconsistent date formats
duplicate orders

Insert 5-10 rows per table.

Keep data realistic for ecommerce.
```

---

# STEP 4 PROMPT — Silver Tables (Clean Data)

```text
Create Silver layer tables for Ecommerce system with cleaned and normalized structure.

Requirements:

remove duplicates
standardize column names
convert dates to timestamp format
create primary keys
create foreign keys

Tables:

SILVER_USERS_SCHEMA:
users
addresses

SILVER_CATALOG_SCHEMA:
categories
products
product_variants

SILVER_ORDERS_SCHEMA:
orders
order_items
payments

SILVER_SHOPPING_SCHEMA:
carts
cart_items

SILVER_SOCIAL_SCHEMA:
reviews

Provide CREATE TABLE SQL.
```

---

# STEP 5 PROMPT — Bronze to Silver Transformation

```text
Generate SQL to transform Bronze tables into Silver tables.

Perform:

remove duplicates using DISTINCT
convert emails to lowercase
standardize timestamps
remove null values
join related tables
normalize columns

Provide INSERT INTO SELECT statements.
```

---

# STEP 6 PROMPT — Gold Tables (Business Analytics)

```text
Create Gold layer aggregated tables for ecommerce analytics.

Tables:

GOLD_USERS_SCHEMA:
customer_summary

GOLD_CATALOG_SCHEMA:
product_performance

GOLD_ORDERS_SCHEMA:
sales_summary

GOLD_SHOPPING_SCHEMA:
cart_conversion

GOLD_SOCIAL_SCHEMA:
product_rating_summary

Each table should include aggregated metrics.

Provide CREATE TABLE SQL.
```

---

# STEP 7 PROMPT — Silver to Gold Transformation

```text
Generate SQL queries to populate Gold tables from Silver tables.

Include metrics:

total orders per customer
total revenue per product
average order value
cart conversion rate
average product rating

Provide INSERT INTO SELECT statements with GROUP BY.
```

---

# STEP 8 PROMPT — Show Data Flow Explanation

```text
Explain the flow of data from Bronze to Silver to Gold for Ecommerce system.

Show examples of:

raw messy data
clean data
aggregated business data

Explain why each layer is needed.
```

---

# STEP 9 PROMPT — Generate Diagram

```text
Create a simple architecture diagram for Ecommerce Bronze Silver Gold layers.

Show:

ECOMMERCE_DB
schemas
tables
data flow arrows

Keep diagram simple for teaching.
```

---

# STEP 10 PROMPT — Generate Questions for Students

```text
Create 10 questions for students based on Ecommerce Bronze Silver Gold architecture.

Include conceptual and SQL based questions.
```

---

# Recommended Teaching Flow

```text
1. Create database
2. Show bronze messy data
3. Show silver cleaned tables
4. Show gold analytics
5. Show SQL transformation
6. Ask students questions
```

---

If you want next level for your course 🚀
I can also convert this into:

* downloadable **PDF (ready for Udemy)**
* **slide deck (PPT)**
* **GitHub repo structure**
* **live demo script (what to say while teaching)**
