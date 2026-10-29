-- ============================================================
-- 06_set_operations.sql — UNION, INTERSECT, EXCEPT
-- ============================================================
-- Set operations combine results from two or more SELECT statements.
-- Both SELECTs must return the same number of columns with compatible types.
-- ============================================================

-- ---------------------------------------------------------
-- A. UNION — All cities where we have customers OR products sold
-- ---------------------------------------------------------
-- UNION removes duplicates; UNION ALL keeps them.

-- Cities from customers
SELECT city AS location, 'Customer City' AS source
FROM dim_customer

UNION

-- Cities that appear in sales (via customer)
SELECT c.city AS location, 'Sales City' AS source
FROM fact_sales fs
JOIN dim_customer c ON fs.customer_id = c.customer_id;

-- Explanation:
--   UNION merges both result sets and removes duplicate rows.
--   Since all our customers have sales, the results will overlap.
--   If we had customers with no sales, they'd still appear from the first query.


-- ---------------------------------------------------------
-- B. UNION ALL — Products sold in January and February (with duplicates)
-- ---------------------------------------------------------
-- Use UNION ALL when you want to keep all rows, including duplicates.

SELECT p.product_name, 'January' AS sale_month
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d ON fs.date_id = d.date_id
WHERE d.month = 1

UNION ALL

SELECT p.product_name, 'February' AS sale_month
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d ON fs.date_id = d.date_id
WHERE d.month = 2

ORDER BY product_name, sale_month;

-- Explanation:
--   UNION ALL keeps every row from both queries.
--   A product sold in both months will appear twice — once per month.


-- ---------------------------------------------------------
-- C. INTERSECT — Products sold in BOTH January AND February
-- ---------------------------------------------------------

SELECT p.product_name
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d ON fs.date_id = d.date_id
WHERE d.month = 1

INTERSECT

SELECT p.product_name
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d ON fs.date_id = d.date_id
WHERE d.month = 2

ORDER BY product_name;

-- Explanation:
--   INTERSECT returns only rows that appear in BOTH result sets.
--   These are products that were sold in January AND also in February.


-- ---------------------------------------------------------
-- D. EXCEPT — Products sold in January but NOT in February
-- ---------------------------------------------------------

SELECT p.product_name
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d ON fs.date_id = d.date_id
WHERE d.month = 1

EXCEPT

SELECT p.product_name
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d ON fs.date_id = d.date_id
WHERE d.month = 2

ORDER BY product_name;

-- Explanation:
--   EXCEPT returns rows from the first query that do NOT appear
--   in the second query. Think of it as "set subtraction."
--   These are January-only products (not sold in February).


-- ---------------------------------------------------------
-- E. EXCEPT (reverse) — Products sold in February but NOT in January
-- ---------------------------------------------------------

SELECT p.product_name
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d ON fs.date_id = d.date_id
WHERE d.month = 2

EXCEPT

SELECT p.product_name
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d ON fs.date_id = d.date_id
WHERE d.month = 1

ORDER BY product_name;

-- Explanation:
--   The reverse EXCEPT — finds February-only products.
--   Note that EXCEPT is NOT symmetric: A EXCEPT B ≠ B EXCEPT A.
