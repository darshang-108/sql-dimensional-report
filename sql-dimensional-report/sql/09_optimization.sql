-- ============================================================
-- 09_optimization.sql — Query Optimization and Indexing
-- ============================================================
-- Demonstrates: creating an index, using EXPLAIN ANALYZE,
-- and interpreting the query plan.
-- ============================================================

-- ---------------------------------------------------------
-- A. Creating a Useful Index
-- ---------------------------------------------------------
-- We frequently filter or join on date_id in fact_sales.
-- An index on (product_id, date_id) speeds up queries that
-- filter by product and/or join with dim_date.

-- Drop if re-running
DROP INDEX IF EXISTS idx_fact_sales_product_date;

CREATE INDEX idx_fact_sales_product_date
    ON fact_sales (product_id, date_id);

-- Explanation:
--   An index is like a book's index — it helps PostgreSQL find rows
--   without scanning the entire table.
--   We chose (product_id, date_id) because many of our analytical
--   queries filter by product and join on date.
--
--   Trade-off:
--     ✔ Faster SELECT queries that filter on product_id or (product_id, date_id).
--     ✗ Slightly slower INSERT/UPDATE/DELETE (the index must also be updated).
--     For an analytics workload (mostly reads), this trade-off is worth it.


-- ---------------------------------------------------------
-- B. EXPLAIN ANALYZE — Inspect a Query Plan
-- ---------------------------------------------------------
-- EXPLAIN shows the plan WITHOUT running the query.
-- EXPLAIN ANALYZE shows the plan AND actually runs the query,
-- giving real execution times.

-- Let's analyze this query: "Total revenue by product category for Q1 2026"

EXPLAIN ANALYZE
SELECT
    p.category,
    SUM(fs.quantity * fs.unit_price) AS total_revenue
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d    ON fs.date_id    = d.date_id
WHERE d.quarter = 1
GROUP BY p.category
ORDER BY total_revenue DESC;

-- ---------------------------------------------------------
-- C. How to Read the EXPLAIN ANALYZE Output
-- ---------------------------------------------------------
-- The output will look something like this (simplified):
--
--   Sort  (cost=X..Y rows=Z)  (actual time=A..B rows=C loops=1)
--     Sort Key: total_revenue DESC
--     ->  HashAggregate  (cost=... rows=...)
--           Group Key: p.category
--           ->  Hash Join  (cost=... rows=...)
--                 Hash Cond: (fs.product_id = p.product_id)
--                 ->  Hash Join  (cost=... rows=...)
--                       Hash Cond: (fs.date_id = d.date_id)
--                       ->  Seq Scan on fact_sales fs
--                       ->  Hash
--                             ->  Seq Scan on dim_date d
--                                   Filter: (quarter = 1)
--                 ->  Hash
--                       ->  Seq Scan on dim_product p
--
-- Beginner-friendly explanation of each node:
--
--   1. Seq Scan on dim_date d (Filter: quarter = 1)
--      PostgreSQL reads ALL rows in dim_date and keeps only Q1 dates.
--      "Seq Scan" = Sequential Scan = reads every row in order.
--
--   2. Seq Scan on fact_sales fs
--      Reads all 40 sales rows.
--
--   3. Hash Join (fs.date_id = d.date_id)
--      Builds a hash table from the dim_date results, then matches
--      each fact_sales row against it. This filters sales to Q1 only.
--
--   4. Hash Join (fs.product_id = p.product_id)
--      Similarly joins with dim_product to get category names.
--
--   5. HashAggregate (Group Key: p.category)
--      Groups the joined rows by category and computes SUM().
--
--   6. Sort (Sort Key: total_revenue DESC)
--      Sorts the final result by revenue, highest first.
--
-- Key numbers to look at:
--   • "actual time" — real elapsed time in milliseconds.
--   • "rows"        — number of rows processed at each step.
--   • "loops"       — how many times that step was executed.
--
-- With only 40 rows, PostgreSQL uses Seq Scan everywhere (full table scans).
-- This is EXPECTED and OPTIMAL for small tables — the overhead of using
-- an index would actually be slower than just reading 40 rows directly.
--
-- The index we created (idx_fact_sales_product_date) would become
-- beneficial when fact_sales grows to thousands or millions of rows.


-- ---------------------------------------------------------
-- D. EXPLAIN (without ANALYZE) — Plan Only, No Execution
-- ---------------------------------------------------------
-- Useful when you want to check the plan without actually running
-- a slow query.

EXPLAIN
SELECT
    c.customer_name,
    SUM(fs.quantity * fs.unit_price) AS total_spent
FROM fact_sales fs
JOIN dim_customer c ON fs.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;

-- Explanation:
--   This shows the estimated plan (cost, rows) but does NOT execute.
--   Use EXPLAIN ANALYZE for actual timings; use plain EXPLAIN when
--   you just want a quick look at the plan.


-- ---------------------------------------------------------
-- E. Additional Index — For Customer-Based Queries
-- ---------------------------------------------------------

DROP INDEX IF EXISTS idx_fact_sales_customer;

CREATE INDEX idx_fact_sales_customer
    ON fact_sales (customer_id);

-- This index benefits queries that filter or group by customer_id.
-- Again, with 40 rows PostgreSQL won't use it, but it's good practice
-- for production schemas.


-- ---------------------------------------------------------
-- Summary: Indexing Best Practices
-- ---------------------------------------------------------
-- 1. Index columns used in WHERE, JOIN, and ORDER BY clauses.
-- 2. Don't over-index — each index slows down writes.
-- 3. Use EXPLAIN ANALYZE to verify whether an index is actually used.
-- 4. For small tables, PostgreSQL prefers Seq Scan (this is normal!).
-- 5. Composite indexes (e.g., product_id + date_id) help multi-column filters.
