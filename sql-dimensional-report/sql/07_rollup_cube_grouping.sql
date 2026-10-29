-- ============================================================
-- 07_rollup_cube_grouping.sql — ROLLUP, CUBE, GROUPING SETS
-- ============================================================
-- These are extensions to GROUP BY that produce subtotals and grand totals
-- in a single query — very useful for sales summary reports.
-- ============================================================

-- ---------------------------------------------------------
-- A. ROLLUP — Hierarchical Subtotals
-- ---------------------------------------------------------
-- ROLLUP(category, product_name) produces:
--   1. Totals per (category, product_name)   — detail rows
--   2. Totals per (category)                 — subtotals
--   3. Grand total                           — one final row

SELECT
    p.category,
    p.product_name,
    SUM(fs.quantity)                  AS total_qty,
    SUM(fs.quantity * fs.unit_price)  AS total_revenue,

    -- GROUPING() returns 1 when the column is aggregated (i.e., it's a subtotal)
    GROUPING(p.category)              AS is_category_total,
    GROUPING(p.product_name)          AS is_product_total

FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
GROUP BY ROLLUP(p.category, p.product_name)
ORDER BY p.category NULLS LAST, p.product_name NULLS LAST;

-- Explanation:
--   Rows where is_product_total = 1 and is_category_total = 0 are CATEGORY subtotals.
--   The row where BOTH = 1 is the GRAND TOTAL.
--   ROLLUP rolls up from right to left: product → category → grand total.
--
-- How to read NULL values:
--   When product_name is NULL and is_product_total = 1, it means
--   "all products in this category" — it's a subtotal, not missing data.


-- ---------------------------------------------------------
-- B. CUBE — All Possible Combinations
-- ---------------------------------------------------------
-- CUBE(category, city) produces subtotals for EVERY combination:
--   1. (category, city)   — detail
--   2. (category)         — subtotal by category
--   3. (city)             — subtotal by city
--   4. ()                 — grand total

SELECT
    p.category,
    c.city,
    SUM(fs.quantity * fs.unit_price)  AS total_revenue,
    COUNT(*)                          AS num_transactions,
    GROUPING(p.category)              AS is_category_total,
    GROUPING(c.city)                  AS is_city_total

FROM fact_sales fs
JOIN dim_product p  ON fs.product_id  = p.product_id
JOIN dim_customer c ON fs.customer_id = c.customer_id
GROUP BY CUBE(p.category, c.city)
ORDER BY p.category NULLS LAST, c.city NULLS LAST;

-- Explanation:
--   CUBE generates more rows than ROLLUP because it includes
--   subtotals for every dimension, not just the hierarchical ones.
--   is_category_total = 1 means "all categories" (city subtotal).
--   is_city_total = 1     means "all cities" (category subtotal).
--   Both = 1              means grand total.


-- ---------------------------------------------------------
-- C. GROUPING SETS — Custom Aggregation Levels
-- ---------------------------------------------------------
-- GROUPING SETS lets you specify EXACTLY which subtotals you want.
-- Here we want: by category, by quarter, and grand total.

SELECT
    p.category,
    d.quarter,
    SUM(fs.quantity * fs.unit_price)  AS total_revenue,
    COUNT(*)                          AS num_transactions

FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d    ON fs.date_id    = d.date_id
GROUP BY GROUPING SETS (
    (p.category),      -- subtotal by category
    (d.quarter),       -- subtotal by quarter
    ()                 -- grand total
)
ORDER BY p.category NULLS LAST, d.quarter NULLS LAST;

-- Explanation:
--   Unlike ROLLUP or CUBE, GROUPING SETS gives you full control.
--   We get exactly 3 types of rows:
--     • One row per category (quarter is NULL)
--     • One row per quarter (category is NULL)
--     • One grand total row (both are NULL)


-- ---------------------------------------------------------
-- D. Practical Tip: Labelling Subtotal Rows
-- ---------------------------------------------------------
-- Use CASE + GROUPING() to replace NULLs with meaningful labels.

SELECT
    CASE WHEN GROUPING(p.category) = 1
         THEN '*** ALL CATEGORIES ***'
         ELSE p.category
    END                                AS category,

    CASE WHEN GROUPING(p.product_name) = 1
         THEN '--- Subtotal ---'
         ELSE p.product_name
    END                                AS product,

    SUM(fs.quantity * fs.unit_price)    AS total_revenue

FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
GROUP BY ROLLUP(p.category, p.product_name)
ORDER BY p.category NULLS LAST, p.product_name NULLS LAST;

-- Explanation:
--   GROUPING(column) returns 1 for subtotal/grand-total rows.
--   We use CASE to display a human-readable label instead of NULL.
--   This makes the output much easier to read in reports.
