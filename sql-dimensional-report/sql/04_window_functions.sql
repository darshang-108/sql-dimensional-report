-- ============================================================
-- 04_window_functions.sql — Window Functions
-- ============================================================
-- Demonstrates: RANK, DENSE_RANK, LAG, LEAD, NTILE,
--               PARTITION BY, ORDER BY, and window frames.
-- ============================================================

-- ---------------------------------------------------------
-- A. RANK and DENSE_RANK — Product Sales Rankings
-- ---------------------------------------------------------
-- RANK:       Leaves gaps after ties (1, 2, 2, 4)
-- DENSE_RANK: No gaps after ties      (1, 2, 2, 3)

SELECT
    p.product_name,
    p.category,
    SUM(fs.quantity * fs.unit_price)  AS total_revenue,

    -- Overall ranking by total revenue
    RANK()       OVER (ORDER BY SUM(fs.quantity * fs.unit_price) DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY SUM(fs.quantity * fs.unit_price) DESC) AS revenue_dense_rank

FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

-- Explanation:
--   Both rank products from highest to lowest revenue.
--   If two products tie, RANK skips the next number; DENSE_RANK does not.


-- ---------------------------------------------------------
-- B. RANK with PARTITION BY — Ranking within each category
-- ---------------------------------------------------------

SELECT
    p.category,
    p.product_name,
    SUM(fs.quantity * fs.unit_price)  AS total_revenue,

    -- Rank resets for each category
    RANK() OVER (
        PARTITION BY p.category
        ORDER BY SUM(fs.quantity * fs.unit_price) DESC
    ) AS rank_in_category

FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY p.category, rank_in_category;

-- Explanation:
--   PARTITION BY p.category splits the data into groups (one per category).
--   RANK() then numbers rows within each group independently.


-- ---------------------------------------------------------
-- C. LAG and LEAD — Monthly Revenue Comparison
-- ---------------------------------------------------------
-- LAG(value, 1)  : gets the value from the PREVIOUS row
-- LEAD(value, 1) : gets the value from the NEXT row

WITH monthly_revenue AS (
    SELECT
        d.year,
        d.month,
        SUM(fs.quantity * fs.unit_price) AS revenue
    FROM fact_sales fs
    JOIN dim_date d ON fs.date_id = d.date_id
    GROUP BY d.year, d.month
)
SELECT
    year,
    month,
    revenue                                              AS current_month_revenue,
    LAG(revenue, 1)  OVER (ORDER BY year, month)         AS prev_month_revenue,
    LEAD(revenue, 1) OVER (ORDER BY year, month)         AS next_month_revenue,

    -- Month-over-month change (NULL for the first month)
    revenue - LAG(revenue, 1) OVER (ORDER BY year, month) AS mom_change

FROM monthly_revenue
ORDER BY year, month;

-- Explanation:
--   LAG looks one row back (previous month).
--   LEAD looks one row ahead (next month).
--   The first month has no previous row, so LAG returns NULL — this is safe.


-- ---------------------------------------------------------
-- D. NTILE(4) — Group Customers into Spending Quartiles
-- ---------------------------------------------------------
-- NTILE(4) divides rows into 4 roughly equal groups (quartiles).
-- Quartile 1 = highest spenders, Quartile 4 = lowest spenders.

SELECT
    c.customer_name,
    c.city,
    SUM(fs.quantity * fs.unit_price)  AS total_spent,

    NTILE(4) OVER (ORDER BY SUM(fs.quantity * fs.unit_price) DESC) AS spending_quartile

FROM fact_sales fs
JOIN dim_customer c ON fs.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY total_spent DESC;

-- Explanation:
--   10 customers divided into 4 groups → groups of 3, 3, 2, 2.
--   Quartile 1 contains the top spenders; quartile 4 the lowest.
--   Useful for customer segmentation (e.g., VIP vs regular customers).


-- ---------------------------------------------------------
-- E. Window Frame Example — Running Total of Monthly Revenue
-- ---------------------------------------------------------
-- A window frame limits WHICH rows the window function considers.
-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW = running total.

WITH monthly_revenue AS (
    SELECT
        d.year,
        d.month,
        SUM(fs.quantity * fs.unit_price) AS revenue
    FROM fact_sales fs
    JOIN dim_date d ON fs.date_id = d.date_id
    GROUP BY d.year, d.month
)
SELECT
    year,
    month,
    revenue,

    -- Running (cumulative) total using an explicit window frame
    SUM(revenue) OVER (
        ORDER BY year, month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total

FROM monthly_revenue
ORDER BY year, month;

-- Explanation:
--   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW means:
--     "start from the very first row and go up to this row."
--   This gives a cumulative sum that grows each month.
--   For example, if Jan=10000 and Feb=12000, the running total in Feb = 22000.
