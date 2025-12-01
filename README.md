# SQL-Optimization-Project
# SQL Query Optimization Showcase

This project details a systematic approach to identifying and resolving performance bottlenecks in inefficient SQL queries. The goal is to demonstrate practical skills in SQL performance tuning, execution plan analysis, and resource management in a database environment.
### Key Skills Demonstrated

* **Advanced SQL:** Proficient use of Window Functions, CTEs (Common Table Expressions), temporary tables, and appropriate joins.
* **Performance Tuning:** Identifying and optimizing expensive operations like full table scans and nested loops.
* **Execution Plan Analysis:** Interpreting database execution plans (`EXPLAIN ANALYZE` or similar) to diagnose bottlenecks.
* **Indexing Strategy:** Understanding and applying appropriate indexing (e.g., clustered vs. non-clustered, composite indexes).
* **Data Modeling Awareness:** Recognizing how query structure interacts with table schema and data distribution.
  
### 1. The Optimization 

###The Problem (Before Optimization)

The original query was designed to calculate email engagement rates (open rate, click rate, etc.) grouped by the user's operating system. However, the structure suffered from low readability and poor performance due to complex, redundant subqueries within the JOIN operations.

The key bottleneck was the use of unnecessary SELECT * FROM table wrapped in parentheses during the LEFT JOIN operations, which complicated the execution plan and likely forced the database to create large, inefficient derived tables. This increases I/O cost and overall execution time.
-- BEFORE OPTIMIZATION (Inefficient Query Snippet)
-- Full code available in [`sql/original_query.sql`](./sql/original_query.sql).
SELECT
    account_session.operating_system,
    COUNT(DISTINCT id_message_open) / COUNT(DISTINCT id_message_sent) * 100 AS open_rate,
    -- ... other rate calculations ...
FROM
    `DA.account` a
JOIN (
    SELECT
        es.id_account AS id_account_sent,
        -- ... other selected fields ...
    FROM
        `DA.email_sent` es
    LEFT JOIN (
        SELECT * FROM `DA.email_open` eo )eo -- REDUNDANT SUBQUERY HERE
    ON
        es.id_message = eo.id_message
    -- ... other joins ...
) email_sent
-- ... complex joins to session data ...
WHERE
    a.is_unsubscribed = 0
GROUP BY
    account_session.operating_system;

###The Solution (After Optimization)

The query was refactored using a Common Table Expression (CTE) to simplify the join logic and modularize the code.

The technique used was isolating the email event joins (email_sent, email_open, email_visit) into a single, clean CTE named email_data. This allowed for direct, simplified LEFT JOIN operations, making the query easier for the database optimizer to process.

This refactoring shifts the heavy lifting into a defined block, resulting in a cleaner execution plan with fewer temporary table writes and a significant reduction in overall execution time.
-- AFTER OPTIMIZATION 
-- Full code available in [`sql/optimized_query.sql`](./sql/optimized_query.sql)
WITH email_data AS (
    SELECT
        es.id_account,
        es.id_message,
        eo.id_message AS open_msg,
        ev.id_message AS visit_msg
    FROM `DA.email_sent` es
    LEFT JOIN `DA.email_open` eo ON es.id_message = eo.id_message -- Clean, Direct Join
    LEFT JOIN `DA.email_visit` ev ON es.id_message = ev.id_message
)
SELECT
    sp.operating_system,
    COUNT(DISTINCT ed.open_msg) * 100 / COUNT(DISTINCT ed.id_message) AS open_rate,
    -- ... other rate calculations ...
FROM email_data ed
JOIN `DA.account` a ON ed.id_account = a.id
-- ... direct joins to session tables ...
WHERE a.is_unsubscribed = 0
GROUP BY sp.operating_system;

### 3. Performance Analysis and Metrics

The optimization resulted in significant, quantifiable gains verified by the BigQuery execution plan metrics.

#### Performance Metrics Summary

The analysis focused on the Slot Time Consumed, which directly measures the CPU resources used by the query. The optimization led to a major decrease in resource consumption.

| Metric | Before Optimization | After Optimization | Improvement |
| :--- | :--- | :--- | :--- |
| **Key Stage Slot Time** | **10 seconds** | **2 seconds** | 80% Reduction |
| **Total Query Slot Time** | 14 seconds | **5 seconds** | **64% Reduction** |
| **Query Elapsed Time** | 4 seconds | 3 seconds | 1 second faster |
| **Primary Bottleneck** | Nested Subqueries/Derived Tables | Eliminated | Refactored using CTE |
