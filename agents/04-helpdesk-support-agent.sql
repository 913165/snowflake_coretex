-- ═══════════════════════════════════════════════════════════════════
--  SUPPORT TICKET AGENT — Demo Script
--  An agent that creates support tickets and sends email notifications
-- ═══════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────
--  SECTION 1 — Setup: Database, Schema, Warehouse
-- ─────────────────────────────────────────────────────────────────

CREATE DATABASE  IF NOT EXISTS helpdesk_db;
CREATE SCHEMA    IF NOT EXISTS helpdesk_db.support;

CREATE WAREHOUSE IF NOT EXISTS agent_wh
  WAREHOUSE_SIZE = 'xsmall'
  AUTO_SUSPEND   = 60
  AUTO_RESUME    = TRUE;

USE DATABASE helpdesk_db;
USE SCHEMA   helpdesk_db.support;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 2 — Create the Support Tickets Table
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE TABLE helpdesk_db.support.tickets (
    ticket_id       INT AUTOINCREMENT START 1001,
    customer_name   VARCHAR(100),
    customer_email  VARCHAR(200),
    category        VARCHAR(50),
    priority        VARCHAR(20),
    subject         VARCHAR(300),
    description     TEXT,
    status          VARCHAR(30) DEFAULT 'Open',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE SEQUENCE helpdesk_db.support.ticket_seq START 1001 INCREMENT 1;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 3 — Email Notification Integration
--  NOTE: Update ALLOWED_RECIPIENTS with your verified email(s)
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE NOTIFICATION INTEGRATION support_email_int
  TYPE    = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('tinumistry@gmail.com');


-- ─────────────────────────────────────────────────────────────────
--  SECTION 4 — Stored Procedure: Create Ticket & Send Email
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE helpdesk_db.support.create_ticket(
    customer_name   STRING,
    customer_email  STRING,
    category        STRING,
    priority        STRING,
    subject         STRING,
    description     STRING
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
AS
$$
def run(session, customer_name, customer_email, category, priority, subject, description):
    ticket_id = session.sql("SELECT helpdesk_db.support.ticket_seq.NEXTVAL").collect()[0][0]

    session.sql(f"""
        INSERT INTO helpdesk_db.support.tickets
            (ticket_id, customer_name, customer_email, category, priority, subject, description)
        VALUES
            ({ticket_id}, '{customer_name}', '{customer_email}', '{category}', '{priority}', '{subject}', '{description}')
    """).collect()

    email_body = f"""
New Support Ticket Created
===========================
Ticket ID   : TKT-{ticket_id}
Customer    : {customer_name} ({customer_email})
Category    : {category}
Priority    : {priority}
Subject     : {subject}

Description:
{description}

---
This is an automated notification from the Support Ticket Agent.
    """.strip()

    try:
        session.call(
            "SYSTEM$SEND_EMAIL",
            "SUPPORT_EMAIL_INT",
            "tinumistry@gmail.com",
            f"[TKT-{ticket_id}] {priority.upper()} — {subject}",
            email_body
        )
        email_status = "Email sent to support team."
    except Exception as e:
        email_status = f"Ticket created but email failed: {str(e)}"

    return f"Ticket TKT-{ticket_id} created successfully. Status: Open. Priority: {priority}. {email_status}"
$$;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 5 — Stored Procedure: Look Up Existing Tickets
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE helpdesk_db.support.lookup_tickets(user_query STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
AS
$$
def run(session, user_query):
    query = user_query.strip().lower()

    if any(k in query for k in ["open", "pending", "active", "unresolved"]):
        sql = """
            SELECT ticket_id, customer_name, category, priority, subject, status, created_at
            FROM helpdesk_db.support.tickets
            WHERE status = 'Open'
            ORDER BY created_at DESC LIMIT 10
        """
    elif any(k in query for k in ["high", "urgent", "critical"]):
        sql = """
            SELECT ticket_id, customer_name, category, priority, subject, status, created_at
            FROM helpdesk_db.support.tickets
            WHERE priority IN ('High', 'Critical')
            ORDER BY created_at DESC LIMIT 10
        """
    elif any(k in query for k in ["recent", "latest", "new", "last"]):
        sql = """
            SELECT ticket_id, customer_name, category, priority, subject, status, created_at
            FROM helpdesk_db.support.tickets
            ORDER BY created_at DESC LIMIT 5
        """
    elif "tkt-" in query:
        import re
        match = re.search(r'tkt-(\d+)', query)
        if match:
            tid = match.group(1)
            sql = f"""
                SELECT ticket_id, customer_name, customer_email, category, priority,
                       subject, description, status, created_at
                FROM helpdesk_db.support.tickets
                WHERE ticket_id = {tid}
            """
        else:
            sql = "SELECT 'Could not parse ticket ID' AS message"
    else:
        sql = """
            SELECT ticket_id, customer_name, category, priority, subject, status, created_at
            FROM helpdesk_db.support.tickets
            ORDER BY created_at DESC LIMIT 10
        """

    rows = session.sql(sql).collect()
    if not rows:
        return "No tickets found matching your query."

    headers = list(rows[0].as_dict().keys())
    lines = [" | ".join(headers), "-" * 80]
    for row in rows:
        lines.append(" | ".join(str(v) for v in row.as_dict().values()))
    return "\n".join(lines)
$$;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 6 — Test the Procedures (before creating the agent)
-- ─────────────────────────────────────────────────────────────────

-- Test creating a ticket
CALL helpdesk_db.support.create_ticket(
    'John Smith',
    'john.smith@example.com',
    'Billing',
    'High',
    'Overcharged on last invoice',
    'I was charged $250 instead of $150 on my March invoice. Please review and issue a refund.'
);

-- Test looking up tickets
CALL helpdesk_db.support.lookup_tickets('show me open tickets');
CALL helpdesk_db.support.lookup_tickets('any high priority tickets?');


-- ─────────────────────────────────────────────────────────────────
--  SECTION 7 — Create the Support Agent
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE AGENT helpdesk_db.support.support_agent
  COMMENT = 'Support agent that creates tickets and sends email notifications'
FROM SPECIFICATION $$
models:
  orchestration: claude-4-sonnet

orchestration:
  budget:
    seconds: 60
    tokens: 6000

instructions:
  system: >
    You are a helpful IT support agent for a company. You assist users by:
    1. Creating support tickets when they report issues or need help.
    2. Looking up existing tickets to check status or find relevant information.

    When a user wants to create a ticket, gather the following details:
    - Customer name
    - Customer email
    - Category (one of: Billing, Technical, Account, General)
    - Priority (one of: Low, Medium, High, Critical)
    - Subject (brief summary)
    - Description (detailed explanation)

    If any details are missing, ask the user for them before creating the ticket.
    Always confirm the ticket details before submitting.

  response: >
    Be professional and empathetic. After creating a ticket, confirm the
    ticket ID and let the user know the support team has been notified via email.
    When showing ticket lookups, summarise the key information clearly.

  orchestration: >
    For requests to create, submit, or log a new ticket — use create_ticket.
    For requests to find, search, check status, or look up tickets — use lookup_tickets.
    If the user is just asking a general question, answer from your own knowledge.

  sample_questions:
    - question: "I need to report a billing issue"
      answer: "I can help you create a support ticket. Let me gather some details."
    - question: "Show me all open tickets"
      answer: "I'll look up all currently open support tickets for you."
    - question: "What's the status of TKT-1001?"
      answer: "Let me look up that ticket for you."
    - question: "I'm having trouble logging in"
      answer: "I can create a technical support ticket for this. What's your name and email?"

tools:
  - tool_spec:
      type: "generic"
      name: "create_ticket"
      description: >
        Creates a new support ticket and sends an email notification to the
        support team. Use this when a user wants to report an issue, request
        help, or log a new support case.
      input_schema:
        type: object
        properties:
          customer_name:
            type: string
            description: "Full name of the customer"
          customer_email:
            type: string
            description: "Customer's email address"
          category:
            type: string
            description: "Ticket category: Billing, Technical, Account, or General"
          priority:
            type: string
            description: "Ticket priority: Low, Medium, High, or Critical"
          subject:
            type: string
            description: "Brief summary of the issue"
          description:
            type: string
            description: "Detailed description of the issue"
        required:
          - customer_name
          - customer_email
          - category
          - priority
          - subject
          - description

  - tool_spec:
      type: "generic"
      name: "lookup_tickets"
      description: >
        Searches and retrieves existing support tickets. Use this when a user
        wants to check ticket status, find open tickets, look up high-priority
        issues, or search for a specific ticket by ID.
      input_schema:
        type: object
        properties:
          user_query:
            type: string
            description: "The user's question about existing tickets"
        required:
          - user_query

tool_resources:
  create_ticket:
    type: "procedure"
    identifier: "helpdesk_db.support.create_ticket"
    execution_environment:
      type: "warehouse"
      warehouse: "AGENT_WH"
  lookup_tickets:
    type: "procedure"
    identifier: "helpdesk_db.support.lookup_tickets"
    execution_environment:
      type: "warehouse"
      warehouse: "AGENT_WH"
$$;


-- ─────────────────────────────────────────────────────────────────
--  SECTION 8 — Test the Agent (after creating it)
-- ─────────────────────────────────────────────────────────────────

-- Create a ticket via the agent
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'helpdesk_db.support.support_agent',
  '{"messages": [{"role": "user", "content": [{"type": "text", "text": "Hi, my name is Sarah Connor (sarah@example.com). I have a critical billing issue — I was double-charged $500 on my account this month. Please create a ticket for this."}]}]}'
) AS response;

-- Look up open tickets via the agent
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'helpdesk_db.support.support_agent',
  '{"messages": [{"role": "user", "content": [{"type": "text", "text": "Show me all open support tickets"}]}]}'
) AS response;

-- Check a specific ticket
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'helpdesk_db.support.support_agent',
  '{"messages": [{"role": "user", "content": [{"type": "text", "text": "What is the status of TKT-1001?"}]}]}'
) AS response;

-- Extract just the answer text
SELECT
  PARSE_JSON(response):content[3]:text::STRING AS answer
FROM (
  SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'helpdesk_db.support.support_agent',
    '{"messages": [{"role": "user", "content": [{"type": "text", "text": "Show me any high priority tickets"}]}]}'
  ) AS response
);


-- ─────────────────────────────────────────────────────────────────
--  SECTION 9 — Cleanup (when done)
-- ─────────────────────────────────────────────────────────────────

DROP AGENT IF EXISTS helpdesk_db.support.support_agent;
DROP PROCEDURE IF EXISTS helpdesk_db.support.create_ticket(STRING, STRING, STRING, STRING, STRING, STRING);
DROP PROCEDURE IF EXISTS helpdesk_db.support.lookup_tickets(STRING);
DROP TABLE IF EXISTS helpdesk_db.support.tickets;
DROP SEQUENCE IF EXISTS helpdesk_db.support.ticket_seq;
DROP NOTIFICATION INTEGRATION IF EXISTS support_email_int;
DROP SCHEMA IF EXISTS helpdesk_db.support;
