-- ============================================================
-- 03_subqueries.sql — Subqueries and EXISTS / NOT EXISTS
-- ============================================================
-- Demonstrates: scalar subquery, correlated subquery, EXISTS, NOT EXISTS.
-- All revenue is calculated as: quantity * unit_price.
-- ============================================================

-- ---------------------------------------------------------
-- A. Scalar Subquery
-- ---------------------------------------------------------
-- A scalar subquery returns exactly ONE value.
-- Here we find each product's total revenue and compare it
-- to the overall average revenue per product.

SELECT
    p.product_name,
    p.category,
    SUM(fs.quantity * fs.unit_price) AS total_revenue,

    -- Scalar subquery: computes the grand average revenue across all products
    (SELECT AVG(product_revenue)
     FROM (
         SELECT SUM(quantity * unit_price) AS product_revenue
         FROM fact_sales
         GROUP BY product_id
     ) AS sub
    ) AS avg_product_revenue

FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

-- Explanation:
--   The inner subquery calculates total revenue for EACH product,
--   then the outer AVG() averages those totals.
--   This single number appears in every row for easy comparison.


-- ---------------------------------------------------------
-- B. Correlated Subquery
-- ---------------------------------------------------------
-- A correlated subquery runs once per row of the outer query.
-- Here we find each customer's total spending and the number
-- of DISTINCT products they bought.

SELECT
    c.customer_name,
    c.city,
    SUM(fs.quantity * fs.unit_price) AS total_spent,

    -- Correlated subquery: counts distinct products for THIS customer
    (SELECT COUNT(DISTINCT fs2.product_id)
     FROM fact_sales fs2
     WHERE fs2.customer_id = c.customer_id    -- correlation!
    ) AS distinct_products_bought

FROM fact_sales fs
JOIN dim_customer c ON fs.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY total_spent DESC;

-- Explanation:
--   For each customer in the outer query, the inner query counts
--   how many different products that SAME customer has purchased.
--   The WHERE clause links inner to outer (that's the "correlation").


-- ---------------------------------------------------------
-- C. EXISTS — Customers who have made at least one purchase
-- ---------------------------------------------------------
-- EXISTS returns TRUE if the subquery returns at least one row.

SELECT
    c.customer_name,
    c.city
FROM dim_customer c
WHERE EXISTS (
    SELECT 1
    FROM fact_sales fs
    WHERE fs.customer_id = c.customer_id
)
ORDER BY c.customer_name;

-- Explanation:
--   For each customer, we check: "does ANY sale exist for this person?"
--   If yes, include them. SELECT 1 is a convention — the actual value
--   doesn't matter; only the existence of a row matters.


-- ---------------------------------------------------------
-- D. NOT EXISTS — Products that have never been sold
-- ---------------------------------------------------------
-- NOT EXISTS returns TRUE if the subquery returns ZERO rows.
-- With our sample data every product has sales, so this will
-- return an empty set — which is actually correct and proves
-- our data has full coverage.

SELECT
    p.product_name,
    p.category
FROM dim_product p
WHERE NOT EXISTS (
    SELECT 1
    FROM fact_sales fs
    WHERE fs.product_id = p.product_id
)
ORDER BY p.product_name;

-- Explanation:
--   This finds products with NO matching sales rows.
--   If the result is empty, it means all products have been sold
--   at least once — which is expected with our sample data.


-- ---------------------------------------------------------
-- E. NOT EXISTS — Customers who have NOT bought from 'Electronics'
-- ---------------------------------------------------------
-- A more interesting NOT EXISTS: find customers who have never
-- purchased any product in the 'Electronics' category.

SELECT
    c.customer_name,
    c.city
FROM dim_customer c
WHERE NOT EXISTS (
    SELECT 1
    FROM fact_sales fs
    JOIN dim_product p ON fs.product_id = p.product_id
    WHERE fs.customer_id = c.customer_id
      AND p.category = 'Electronics'
)
ORDER BY c.customer_name;

-- Explanation:
--   For each customer, check if there's ANY sale of an Electronics product.
--   If NOT, include that customer. This is useful for targeted marketing.
