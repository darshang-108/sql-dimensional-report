-- ============================================================
-- 08_views.sql — Standard and Materialized Views
-- ============================================================
-- A VIEW is a saved query — it doesn't store data, it runs the query
-- each time you SELECT from it.
-- A MATERIALIZED VIEW stores the query result physically and must
-- be refreshed manually when underlying data changes.
-- ============================================================

-- ---------------------------------------------------------
-- A. Standard View — Monthly Sales Summary
-- ---------------------------------------------------------
DROP VIEW IF EXISTS v_monthly_sales_summary;

CREATE VIEW v_monthly_sales_summary AS
SELECT
    d.year,
    d.month,
    p.category,
    COUNT(*)                          AS num_transactions,
    SUM(fs.quantity)                  AS total_qty,
    SUM(fs.quantity * fs.unit_price)  AS total_revenue,
    ROUND(AVG(fs.quantity * fs.unit_price), 2) AS avg_transaction_value
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_date d    ON fs.date_id    = d.date_id
GROUP BY d.year, d.month, p.category;

COMMENT ON VIEW v_monthly_sales_summary IS
    'Aggregated monthly revenue by product category. Use for dashboards and reports.';

-- Usage: query the view like a regular table
SELECT * FROM v_monthly_sales_summary
ORDER BY year, month, category;

-- Explanation:
--   The view encapsulates a complex GROUP BY query.
--   Anyone can run SELECT * FROM v_monthly_sales_summary without
--   knowing the underlying joins and aggregations.
--   The data is always up-to-date because the query runs each time.


-- ---------------------------------------------------------
-- B. Standard View — Customer Spending Summary
-- ---------------------------------------------------------
DROP VIEW IF EXISTS v_customer_spending;

CREATE VIEW v_customer_spending AS
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    COUNT(*)                          AS num_purchases,
    SUM(fs.quantity * fs.unit_price)  AS total_spent,
    ROUND(AVG(fs.quantity * fs.unit_price), 2) AS avg_order_value
FROM fact_sales fs
JOIN dim_customer c ON fs.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.city;

COMMENT ON VIEW v_customer_spending IS
    'Per-customer spending summary for segmentation and analysis.';

-- Usage
SELECT * FROM v_customer_spending
ORDER BY total_spent DESC;


-- ---------------------------------------------------------
-- C. Materialized View — Category Revenue (Cached)
-- ---------------------------------------------------------
-- A materialized view stores results on disk for faster reads.
-- Useful when the query is expensive and data doesn't change often.

DROP MATERIALIZED VIEW IF EXISTS mv_category_revenue;

CREATE MATERIALIZED VIEW mv_category_revenue AS
SELECT
    p.category,
    SUM(fs.quantity * fs.unit_price)  AS total_revenue,
    COUNT(*)                          AS num_sales,
    SUM(fs.quantity)                  AS total_qty
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
GROUP BY p.category;

COMMENT ON MATERIALIZED VIEW mv_category_revenue IS
    'Cached category-level revenue. Refresh with: REFRESH MATERIALIZED VIEW mv_category_revenue;';

-- Usage
SELECT * FROM mv_category_revenue
ORDER BY total_revenue DESC;

-- To update the materialized view after new data is inserted:
-- REFRESH MATERIALIZED VIEW mv_category_revenue;

-- Explanation:
--   Standard view:       runs the query every time → always fresh, but slower.
--   Materialized view:   stores the result → faster reads, but can be stale.
--
--   When to use materialized views:
--     • Dashboard queries that run frequently on large datasets.
--     • Reports where data changes infrequently (e.g., daily refresh).
--
--   When NOT to use:
--     • When you need real-time data.
--     • When the underlying tables change very frequently.
