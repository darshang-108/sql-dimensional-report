-- ============================================================
-- 02_sample_data.sql — Sample Data for E-commerce Sales Analytics
-- ============================================================
-- 10 products, 10 customers, ~40 sales across 5 months (Jan–May 2026).
-- Designed so that rankings and monthly comparisons produce meaningful output.
-- ============================================================

-- ---------------------------------------------------------
-- Products (10 items across 4 categories)
-- ---------------------------------------------------------
INSERT INTO dim_product (product_name, category) VALUES
    ('Wireless Mouse',      'Electronics'),
    ('Mechanical Keyboard', 'Electronics'),
    ('USB-C Hub',           'Electronics'),
    ('Running Shoes',       'Footwear'),
    ('Casual Sneakers',     'Footwear'),
    ('Cotton T-Shirt',      'Clothing'),
    ('Denim Jeans',         'Clothing'),
    ('Yoga Mat',            'Fitness'),
    ('Resistance Bands',    'Fitness'),
    ('Water Bottle',        'Fitness');

-- ---------------------------------------------------------
-- Customers (10 customers across 5 cities)
-- ---------------------------------------------------------
INSERT INTO dim_customer (customer_name, city) VALUES
    ('Aarav Sharma',   'Mumbai'),
    ('Priya Patel',    'Delhi'),
    ('Rohan Mehta',    'Bangalore'),
    ('Sneha Iyer',     'Chennai'),
    ('Vikram Singh',   'Pune'),
    ('Ananya Das',     'Mumbai'),
    ('Karthik Nair',   'Bangalore'),
    ('Neha Gupta',     'Delhi'),
    ('Arjun Reddy',    'Chennai'),
    ('Divya Joshi',    'Pune');

-- ---------------------------------------------------------
-- Dates (one row per sale date, spanning Jan–May 2026)
-- ---------------------------------------------------------
INSERT INTO dim_date (sale_date, month, quarter, year) VALUES
    ('2026-01-05', 1, 1, 2026),   -- date_id = 1
    ('2026-01-12', 1, 1, 2026),   -- date_id = 2
    ('2026-01-20', 1, 1, 2026),   -- date_id = 3
    ('2026-02-03', 2, 1, 2026),   -- date_id = 4
    ('2026-02-14', 2, 1, 2026),   -- date_id = 5
    ('2026-02-22', 2, 1, 2026),   -- date_id = 6
    ('2026-03-01', 3, 1, 2026),   -- date_id = 7
    ('2026-03-10', 3, 1, 2026),   -- date_id = 8
    ('2026-03-25', 3, 1, 2026),   -- date_id = 9
    ('2026-04-05', 4, 2, 2026),   -- date_id = 10
    ('2026-04-15', 4, 2, 2026),   -- date_id = 11
    ('2026-04-28', 4, 2, 2026),   -- date_id = 12
    ('2026-05-02', 5, 2, 2026),   -- date_id = 13
    ('2026-05-10', 5, 2, 2026),   -- date_id = 14
    ('2026-05-20', 5, 2, 2026);   -- date_id = 15

-- ---------------------------------------------------------
-- Sales Transactions (40 rows)
-- ---------------------------------------------------------
-- Revenue = quantity * unit_price (calculated in queries, not stored)
--
-- The data is designed so that:
--   • Some products sell more than others (for ranking)
--   • Revenue varies month to month (for MoM growth)
--   • Some customers spend a lot, others less (for NTILE quartiles)
-- ---------------------------------------------------------

INSERT INTO fact_sales (product_id, customer_id, date_id, quantity, unit_price) VALUES
    -- January sales (8 transactions)
    (1,  1,  1,  2,  599.00),    -- Wireless Mouse
    (2,  2,  1,  1, 2499.00),    -- Mechanical Keyboard
    (6,  3,  2,  3,  499.00),    -- Cotton T-Shirt
    (4,  4,  2,  1, 3299.00),    -- Running Shoes
    (8,  5,  3,  2,  899.00),    -- Yoga Mat
    (10, 6,  3,  4,  349.00),    -- Water Bottle
    (3,  7,  1,  1, 1799.00),    -- USB-C Hub
    (5,  8,  2,  1, 2199.00),    -- Casual Sneakers

    -- February sales (8 transactions)
    (1,  1,  4,  3,  599.00),    -- Wireless Mouse
    (2,  9,  4,  2, 2499.00),    -- Mechanical Keyboard
    (7,  2,  5,  1, 1999.00),    -- Denim Jeans
    (9,  3,  5,  5,  399.00),    -- Resistance Bands
    (4,  10, 6,  2, 3299.00),    -- Running Shoes
    (6,  5,  6,  2,  499.00),    -- Cotton T-Shirt
    (3,  4,  4,  1, 1799.00),    -- USB-C Hub
    (8,  6,  5,  1,  899.00),    -- Yoga Mat

    -- March sales (8 transactions)
    (1,  2,  7,  1,  599.00),    -- Wireless Mouse
    (2,  1,  7,  1, 2499.00),    -- Mechanical Keyboard
    (5,  3,  8,  2, 2199.00),    -- Casual Sneakers
    (7,  4,  8,  2, 1999.00),    -- Denim Jeans
    (10, 7,  9,  3,  349.00),    -- Water Bottle
    (9,  8,  9,  2,  399.00),    -- Resistance Bands
    (4,  9,  7,  1, 3299.00),    -- Running Shoes
    (6,  10, 8,  4,  499.00),    -- Cotton T-Shirt

    -- April sales (8 transactions)
    (2,  1, 10,  2, 2499.00),    -- Mechanical Keyboard
    (1,  5, 10,  4,  599.00),    -- Wireless Mouse
    (3,  2, 11,  2, 1799.00),    -- USB-C Hub
    (7,  3, 11,  1, 1999.00),    -- Denim Jeans
    (4,  6, 12,  1, 3299.00),    -- Running Shoes
    (8,  7, 12,  3,  899.00),    -- Yoga Mat
    (9,  4, 10,  3,  399.00),    -- Resistance Bands
    (5,  8, 11,  1, 2199.00),    -- Casual Sneakers

    -- May sales (8 transactions)
    (1,  1, 13,  2,  599.00),    -- Wireless Mouse
    (2,  3, 13,  3, 2499.00),    -- Mechanical Keyboard
    (6,  2, 14,  5,  499.00),    -- Cotton T-Shirt
    (4,  9, 14,  2, 3299.00),    -- Running Shoes
    (10, 10,15,  6,  349.00),    -- Water Bottle
    (7,  5, 15,  2, 1999.00),    -- Denim Jeans
    (3,  6, 13,  1, 1799.00),    -- USB-C Hub
    (8,  4, 14,  2,  899.00);    -- Yoga Mat

-- ---------------------------------------------------------
-- Quick sanity check (run after loading)
-- ---------------------------------------------------------
-- SELECT COUNT(*) AS total_sales FROM fact_sales;          -- Should be 40
-- SELECT COUNT(*) AS total_products FROM dim_product;      -- Should be 10
-- SELECT COUNT(*) AS total_customers FROM dim_customer;    -- Should be 10
-- SELECT COUNT(*) AS total_dates FROM dim_date;            -- Should be 15
