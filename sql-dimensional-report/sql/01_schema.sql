-- ============================================================
-- 01_schema.sql — Star Schema for E-commerce Sales Analytics
-- ============================================================
-- This script creates a simple star schema with:
--   1 fact table  : fact_sales
--   3 dimension tables : dim_product, dim_customer, dim_date
--
-- Normalization notes (for viva):
--   1NF : Every column holds atomic (single) values; no repeating groups.
--   2NF : Every non-key column depends on the WHOLE primary key (not part of it).
--   3NF : No non-key column depends on another non-key column.
--   Our dimension tables are already in 3NF because each non-key attribute
--   depends only on the primary key and nothing else.
-- ============================================================

-- Clean up if re-running
DROP TABLE IF EXISTS fact_sales   CASCADE;
DROP TABLE IF EXISTS dim_product  CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_date     CASCADE;

-- ---------------------------------------------------------
-- Dimension: Products
-- ---------------------------------------------------------
CREATE TABLE dim_product (
    product_id   SERIAL       PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(50)  NOT NULL
);

COMMENT ON TABLE  dim_product IS 'Product dimension — stores product details.';
COMMENT ON COLUMN dim_product.category IS 'Product category such as Electronics, Clothing, etc.';

-- ---------------------------------------------------------
-- Dimension: Customers
-- ---------------------------------------------------------
CREATE TABLE dim_customer (
    customer_id   SERIAL       PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    city          VARCHAR(50)  NOT NULL
);

COMMENT ON TABLE dim_customer IS 'Customer dimension — stores customer details.';

-- ---------------------------------------------------------
-- Dimension: Date
-- ---------------------------------------------------------
CREATE TABLE dim_date (
    date_id  SERIAL  PRIMARY KEY,
    sale_date DATE   NOT NULL UNIQUE,
    month    INT     NOT NULL CHECK (month BETWEEN 1 AND 12),
    quarter  INT     NOT NULL CHECK (quarter BETWEEN 1 AND 4),
    year     INT     NOT NULL
);

COMMENT ON TABLE dim_date IS 'Date dimension — one row per calendar date used in sales.';

-- ---------------------------------------------------------
-- Fact: Sales
-- ---------------------------------------------------------
CREATE TABLE fact_sales (
    sale_id     SERIAL         PRIMARY KEY,
    product_id  INT            NOT NULL REFERENCES dim_product(product_id),
    customer_id INT            NOT NULL REFERENCES dim_customer(customer_id),
    date_id     INT            NOT NULL REFERENCES dim_date(date_id),
    quantity    INT            NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2)  NOT NULL CHECK (unit_price > 0)
);

COMMENT ON TABLE  fact_sales IS 'Fact table — each row is one sales transaction.';
COMMENT ON COLUMN fact_sales.unit_price IS 'Price per unit at the time of sale.';

-- Revenue is calculated as: quantity * unit_price (not stored, computed in queries).

-- ============================================================
-- Normalization explanation (for the report / viva)
-- ============================================================
-- 1NF check:
--   ✔ All columns contain atomic values (no arrays or comma-separated lists).
--   ✔ Each table has a primary key.
--
-- 2NF check:
--   ✔ All non-key columns depend on the ENTIRE primary key.
--      (Our PKs are single-column, so 2NF is automatically satisfied.)
--
-- 3NF check:
--   ✔ No transitive dependencies.
--      e.g., in dim_product, both product_name and category depend
--      directly on product_id — category does NOT depend on product_name.
--
-- Star schema note:
--   The fact table (fact_sales) sits at the centre.
--   Dimension tables (dim_product, dim_customer, dim_date) surround it.
--   Foreign keys in fact_sales point to each dimension's primary key.
-- ============================================================
