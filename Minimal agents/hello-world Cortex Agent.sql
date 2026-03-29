
CREATE DATABASE IF NOT EXISTS demo_db;

CREATE SCHEMA IF NOT EXISTS demo_db.agents;

CREATE OR REPLACE AGENT demo_db.agents.hello_agent
  COMMENT = 'Minimal hello-world Cortex Agent'
FROM SPECIFICATION $$
models:
  orchestration: claude-4-sonnet
orchestration:
  budget:
    seconds: 30
    tokens: 2000
instructions:
  system: "You are a helpful Snowflake assistant. Be concise."
  response: "Reply in 1-2 sentences max."
  sample_questions:
    - question: "What is Snowflake?"
      answer: "Snowflake is a cloud-based data platform that provides data warehousing, data lakes, and data sharing capabilities."
    - question: "Explain the difference between a view and a materialized view."
      answer: "A view is a virtual table defined by a query, while a materialized view stores precomputed results for faster reads."
    - question: "What are Snowflake virtual warehouses?"
      answer: "Virtual warehouses are compute clusters that execute queries and DML operations independently of storage."
    - question: "How does Snowflake handle concurrency?"
      answer: "Snowflake uses multi-cluster warehouses that can automatically scale out to handle concurrent workloads without contention."
    - question: "What is a Cortex Agent?"
      answer: "A Cortex Agent is an AI-powered assistant in Snowflake that can orchestrate tools like Cortex Analyst and Cortex Search to answer questions."
$$
