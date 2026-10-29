-- ============================================================
-- 05_cte_mom_growth.sql — CTE-based Month-over-Month Sales Report
-- ============================================================
-- Demonstrates: Common Table Expressions (CTEs), LAG for MoM comparison,
--               safe division-by-zero handling, and a recursive CTE.
-- ============================================================

-- ---------------------------------------------------------
-- A. Month-over-Month (MoM) Sales Growth Report
-- ---------------------------------------------------------
-- Shows: current month revenue, previous month revenue,
--        absolute change, and percentage growth.

WITH monthly_sales AS (
    -- Step 1: Aggregate revenue by month
    SELECT
        d.year,
        d.month,
        SUM(fs.quantity * fs.unit_price) AS revenue
    FROM fact_sales fs
    JOIN dim_date d ON fs.date_id = d.date_id
    GROUP BY d.year, d.month
),
mom_comparison AS (
    -- Step 2: Use LAG to get previous month's revenue
    SELECT
        year,
        month,
        revenue                                          AS current_revenue,
        LAG(revenue) OVER (ORDER BY year, month)         AS prev_revenue
    FROM monthly_sales
)
-- Step 3: Calculate change and growth %
SELECT
    year,
    month,
    current_revenue,
    prev_revenue,

    -- Absolute change (NULL for the first month — no previous data)
    current_revenue - prev_revenue                       AS abs_change,

    -- Percentage growth with safe division:
    --   NULLIF(prev_revenue, 0) returns NULL if prev_revenue is 0,
    --   preventing a division-by-zero error.
    --   For the first month, prev_revenue is NULL, so result is also NULL.
    ROUND(
        (current_revenue - prev_revenue) * 100.0
        / NULLIF(prev_revenue, 0),
        2
    )                                                    AS growth_pct

FROM mom_comparison
ORDER BY year, month;

-- Explanation:
--   CTE 1 (monthly_sales): gets total revenue per month.
--   CTE 2 (mom_comparison): attaches previous month's revenue using LAG.
--   Final SELECT: calculates the difference and percentage.
--
--   NULLIF handles two edge cases:
--     • First month: prev_revenue is NULL → result is NULL (safe).
--     • Zero revenue month: prev_revenue is 0 → NULLIF returns NULL (safe).


-- ---------------------------------------------------------
-- B. Recursive CTE Example — Generate a Month Series
-- ---------------------------------------------------------
-- A recursive CTE calls itself to build rows iteratively.
-- Here we generate the months Jan–Dec 2026 without a calendar table.

WITH RECURSIVE month_series AS (
    -- Anchor: start with January
    SELECT 1 AS month_num, 'January' AS month_name

    UNION ALL

    -- Recursive step: add 1 to the month number
    SELECT
        month_num + 1,
        TO_CHAR(MAKE_DATE(2026, month_num + 1, 1), 'Month')
    FROM month_series
    WHERE month_num < 12   -- stop condition: don't go past December
)
SELECT
    month_num,
    TRIM(month_name) AS month_name
FROM month_series;

-- Explanation:
--   1. The anchor member produces the first row: month 1, "January".
--   2. The recursive member takes the previous row and adds 1 to the month.
--   3. The WHERE clause stops recursion at month 12.
--   4. MAKE_DATE + TO_CHAR converts the month number to a name.
--   5. This is a simple, safe recursion — it always terminates.
--
--   Practical use: you could LEFT JOIN this series with actual sales
--   to show months with zero sales (which would otherwise be missing).


-- ---------------------------------------------------------
-- C. Using the Month Series to Find Months with No Sales
-- ---------------------------------------------------------
-- LEFT JOIN the generated series with actual sales to spot gaps.

WITH RECURSIVE month_series AS (
    SELECT 1 AS month_num
    UNION ALL
    SELECT month_num + 1 FROM month_series WHERE month_num < 12
),
actual_months AS (
    SELECT DISTINCT d.month
    FROM fact_sales fs
    JOIN dim_date d ON fs.date_id = d.date_id
    WHERE d.year = 2026
)
SELECT
    ms.month_num,
    CASE
        WHEN am.month IS NOT NULL THEN 'Has Sales'
        ELSE 'No Sales'
    END AS status
FROM month_series ms
LEFT JOIN actual_months am ON ms.month_num = am.month
ORDER BY ms.month_num;

-- Explanation:
--   This shows all 12 months and flags which ones have sales data.
--   Months 6–12 will show "No Sales" since our data only covers Jan–May.
