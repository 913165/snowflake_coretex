Now lets see the simple and small examples of bronze,silver and gold schema

---

# Real-world Naming Pattern

Same table name across layers:

```id="h6j9r3"
ECOMMERCE_DB
│
├── BRONZE
│     orders
│
├── SILVER
│     orders
│
└── GOLD
      orders
```

Each layer improves quality and usability of the **same business entity**.

---

# Why same table name is better

### 1. Business consistency

Business users always think in terms of:

* orders
* customers
* products

not:

* orders_raw
* orders_clean_v2
* orders_final_v3

---

### 2. Easy lineage understanding

```
BRONZE.orders  → raw ingestion
SILVER.orders  → validated data
GOLD.orders    → analytics ready
```

Very intuitive.

---

### 3. Easier querying for analysts

Analysts usually query only GOLD layer:

```sql
SELECT * FROM GOLD.orders;
```

They don't need to know transformation complexity.

---

### 4. Industry standard practice

Common medallion naming:

| Layer  | Table name |
| ------ | ---------- |
| Bronze | orders     |
| Silver | orders     |
| Gold   | orders     |

Layer shows maturity of data.

---

# Updated Simple Structure

```id="7y1i7q"
ECOMMERCE_DB
│
├── BRONZE
│     orders
│
├── SILVER
│     orders
│
└── GOLD
      orders
```

---

# Cortex Prompts using real-world naming

## Step 1

> create database ECOMMERCE_DB and create schemas BRONZE, SILVER and GOLD

---

## Step 2 — Bronze layer

> create table BRONZE.orders containing raw ecommerce order data with columns order_id, customer_email, order_date stored as text, product_name, quantity stored as text, price stored as text and country with inconsistent casing

---

## Step 3 — Silver layer

> create SILVER.orders by transforming BRONZE.orders by converting order_date into date datatype, converting quantity and price into numeric datatypes, removing duplicate records and standardizing country and product_name values

---

## Step 4 — Gold layer

> create GOLD.orders aggregated from SILVER.orders containing order_date, country, total_orders, total_quantity and total_revenue grouped by order_date and country

---

# How to explain simply

Same business table
different quality level

```
orders table evolves through layers
```

```id="54e9xx"
BRONZE.orders → raw data
SILVER.orders → cleaned data
GOLD.orders   → business metrics
```

---

# Important clarification (real projects)

Sometimes GOLD layer may slightly change structure (aggregation), but name still reflects business meaning:

Examples:

```
GOLD.orders
GOLD.sales
GOLD.order_metrics
```

Still business-oriented names.

---

