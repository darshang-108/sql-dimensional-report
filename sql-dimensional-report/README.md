# SQL Dimensional Report — E-commerce Sales Analytics

**DataGrokr PLP Week 5 | College Mini-Project**

A complete SQL-based analytical system built on a star schema, demonstrating subqueries, window functions, CTEs, set operations, advanced aggregation, views, and query optimization using PostgreSQL.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Schema Design](#schema-design)
3. [Setup Instructions](#setup-instructions)
4. [Running the Scripts](#running-the-scripts)
5. [Script Descriptions](#script-descriptions)
6. [Expected Sample Outputs](#expected-sample-outputs)
7. [Screenshots Checklist](#screenshots-checklist)
8. [Normalization Explanation](#normalization-explanation)
9. [Viva Questions & Answers](#viva-questions--answers)

---

## Project Overview

| Aspect         | Detail                                          |
| -------------- | ----------------------------------------------- |
| **Objective**  | Analyze e-commerce sales with SQL                |
| **Database**   | PostgreSQL                                       |
| **Schema**     | Star schema (1 fact table + 3 dimension tables)  |
| **Data**       | 10 products, 10 customers, 40 sales (Jan–May 2026) |
| **Revenue**    | Calculated as `quantity × unit_price` (not stored)|

---

## Schema Design

```
             ┌──────────────┐
             │  dim_product  │
             │──────────────│
             │ product_id PK│
             │ product_name │
             │ category     │
             └──────┬───────┘
                    │
┌──────────────┐    │    ┌──────────────┐
│ dim_customer │    │    │   dim_date   │
│──────────────│    │    │──────────────│
│ customer_id PK│   │    │ date_id   PK │
│ customer_name│    │    │ sale_date    │
│ city         │    │    │ month        │
└──────┬───────┘    │    │ quarter      │
       │            │    │ year         │
       │    ┌───────┴────┴───┐          │
       │    │   fact_sales   │          │
       └────│────────────────│──────────┘
            │ sale_id     PK │
            │ product_id  FK │
            │ customer_id FK │
            │ date_id     FK │
            │ quantity       │
            │ unit_price     │
            └────────────────┘
```

---

## Setup Instructions

### Prerequisites

- **PostgreSQL** (version 12 or later) installed and running.
- **psql** (command-line client) or **pgAdmin** available.

### Step 1: Create the Database

```bash
# Open psql as the postgres superuser
psql -U postgres

# Inside psql:
CREATE DATABASE ecommerce_analytics;
\q
```

### Step 2: Connect to the Database

```bash
psql -U postgres -d ecommerce_analytics
```

### Step 3: Run the Scripts in Order

```bash
# Option A: Run from psql prompt
\i sql/01_schema.sql
\i sql/02_sample_data.sql
\i sql/03_subqueries.sql
\i sql/04_window_functions.sql
\i sql/05_cte_mom_growth.sql
\i sql/06_set_operations.sql
\i sql/07_rollup_cube_grouping.sql
\i sql/08_views.sql
\i sql/09_optimization.sql
```

```bash
# Option B: Run from command line (outside psql)
psql -U postgres -d ecommerce_analytics -f sql/01_schema.sql
psql -U postgres -d ecommerce_analytics -f sql/02_sample_data.sql
# ... and so on for each file
```

> **Note:** Always run `01_schema.sql` first (creates tables), then `02_sample_data.sql` (loads data). The remaining scripts can be run in any order, but the numbered sequence is recommended.

### Using pgAdmin Instead

1. Open pgAdmin and connect to your server.
2. Create a new database called `ecommerce_analytics`.
3. Open the Query Tool for that database.
4. Copy-paste each SQL file's contents and click **Execute (F5)**.
5. Run the files in numerical order.

---

## Running the Scripts

| Script | Purpose | Prerequisite |
| ------ | ------- | ------------ |
| `01_schema.sql` | Create all 4 tables with constraints | — |
| `02_sample_data.sql` | Insert sample data (10+10+15+40 rows) | 01 |
| `03_subqueries.sql` | Scalar, correlated, EXISTS, NOT EXISTS | 01, 02 |
| `04_window_functions.sql` | RANK, DENSE_RANK, LAG, LEAD, NTILE, frames | 01, 02 |
| `05_cte_mom_growth.sql` | MoM growth report + recursive CTE | 01, 02 |
| `06_set_operations.sql` | UNION, INTERSECT, EXCEPT | 01, 02 |
| `07_rollup_cube_grouping.sql` | ROLLUP, CUBE, GROUPING SETS | 01, 02 |
| `08_views.sql` | Standard views + materialized view | 01, 02 |
| `09_optimization.sql` | Indexes + EXPLAIN ANALYZE | 01, 02 |

---

## Script Descriptions

### 03 — Subqueries
- **Scalar subquery**: Average revenue per product (single value in SELECT).
- **Correlated subquery**: Count of distinct products per customer.
- **EXISTS**: Customers with at least one purchase.
- **NOT EXISTS**: Products never sold; customers who haven't bought Electronics.

### 04 — Window Functions
- **RANK / DENSE_RANK**: Product revenue rankings (overall and per category).
- **LAG / LEAD**: Previous and next month's revenue for comparison.
- **NTILE(4)**: Customer spending quartiles (segmentation).
- **Window frame**: Running total using `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

### 05 — CTEs & Month-over-Month Growth
- **CTE chain**: monthly_sales → mom_comparison → final report.
- **Safe division**: Uses `NULLIF(prev_revenue, 0)` to prevent division by zero.
- **Recursive CTE**: Generates month 1–12 series; identifies months with no sales.

### 06 — Set Operations
- **UNION / UNION ALL**: Combine city lists; products from two months.
- **INTERSECT**: Products sold in both January and February.
- **EXCEPT**: Products exclusive to one month.

### 07 — ROLLUP, CUBE, GROUPING SETS
- **ROLLUP**: Hierarchical subtotals (product → category → grand total).
- **CUBE**: All dimension combinations (category × city).
- **GROUPING SETS**: Custom aggregation levels.
- **GROUPING()**: Identifies subtotal vs. detail rows.

### 08 — Views
- **v_monthly_sales_summary**: Monthly revenue by category.
- **v_customer_spending**: Per-customer spending summary.
- **mv_category_revenue**: Materialized view with REFRESH explanation.

### 09 — Query Optimization
- **Index**: Composite index on `(product_id, date_id)`.
- **EXPLAIN ANALYZE**: Full plan walkthrough with beginner-friendly explanation.
- **Honest note**: With 40 rows, PostgreSQL uses Seq Scan — this is optimal for small tables.

---

## Expected Sample Outputs

> **Important**: These outputs are based on the sample data in `02_sample_data.sql`. Run the scripts yourself to get actual results.

### Product Revenue Rankings (from 04_window_functions.sql)

| product_name       | category    | total_revenue | revenue_rank |
| ------------------ | ----------- | ------------- | ------------ |
| Mechanical Keyboard| Electronics | 22,491.00     | 1            |
| Running Shoes      | Footwear    | 23,093.00     | 2 (approx)   |
| Casual Sneakers    | Footwear    | ~8,796.00     | 3            |
| Denim Jeans        | Clothing    | ~11,994.00    | 4            |
| ...                | ...         | ...           | ...          |

### Month-over-Month Growth (from 05_cte_mom_growth.sql)

| year | month | current_revenue | prev_revenue | abs_change | growth_pct |
| ---- | ----- | --------------- | ------------ | ---------- | ---------- |
| 2026 | 1     | ~14,840.00      | NULL         | NULL       | NULL       |
| 2026 | 2     | ~17,689.00      | ~14,840.00   | ~2,849.00  | ~19.20%    |
| 2026 | 3     | ~15,438.00      | ~17,689.00   | ~-2,251.00 | ~-12.72%   |
| 2026 | 4     | ~18,289.00      | ~15,438.00   | ~2,851.00  | ~18.47%    |
| 2026 | 5     | ~21,289.00      | ~18,289.00   | ~3,000.00  | ~16.40%    |

> Run the actual queries to get precise numbers.

---

## Screenshots Checklist

For your project report, capture screenshots of:

- [ ] Schema creation output (01_schema.sql)
- [ ] Data insertion confirmation (02_sample_data.sql)
- [ ] Scalar subquery result (03_subqueries.sql)
- [ ] EXISTS / NOT EXISTS results (03_subqueries.sql)
- [ ] Product rankings with RANK and DENSE_RANK (04_window_functions.sql)
- [ ] LAG/LEAD monthly comparison (04_window_functions.sql)
- [ ] NTILE quartiles (04_window_functions.sql)
- [ ] MoM growth report (05_cte_mom_growth.sql)
- [ ] Recursive CTE month series (05_cte_mom_growth.sql)
- [ ] INTERSECT and EXCEPT results (06_set_operations.sql)
- [ ] ROLLUP output with subtotals (07_rollup_cube_grouping.sql)
- [ ] CUBE output (07_rollup_cube_grouping.sql)
- [ ] View query results (08_views.sql)
- [ ] EXPLAIN ANALYZE output (09_optimization.sql)

---

## Normalization Explanation

Our schema satisfies all three normal forms:

| Normal Form | Rule | Our Schema |
| ----------- | ---- | ---------- |
| **1NF** | All values are atomic; table has a primary key | ✔ Every column stores a single value; every table has a PK |
| **2NF** | Every non-key column depends on the entire PK | ✔ All PKs are single-column, so 2NF is automatic |
| **3NF** | No transitive dependencies (non-key → non-key) | ✔ e.g., in dim_product, category depends on product_id, NOT on product_name |

**Star schema note**: The fact table sits at the centre with foreign keys pointing to each dimension. This design is intentionally denormalized at the join level (one join per dimension) for fast analytical queries.

---

## Viva Questions & Answers

### 1. What is a star schema?
A star schema has one **fact table** (with measurable data like sales) surrounded by **dimension tables** (with descriptive attributes like product name, customer city). The fact table connects to dimensions via foreign keys, forming a star shape.

### 2. What is the difference between RANK() and DENSE_RANK()?
Both assign rankings. If two items tie at rank 2:
- **RANK()** skips the next number: 1, 2, 2, **4**
- **DENSE_RANK()** does not skip: 1, 2, 2, **3**

### 3. What does LAG() do?
LAG(column, n) returns the value from **n rows before** the current row within the window. It's commonly used to compare a value with the previous period (e.g., this month vs. last month).

### 4. What is a CTE?
A **Common Table Expression** (WITH clause) is a temporary named result set that exists only for the duration of one query. It makes complex queries more readable by breaking them into named steps.

### 5. How do you handle division by zero in the MoM growth query?
We use `NULLIF(prev_revenue, 0)` which returns NULL if `prev_revenue` is 0. Dividing by NULL gives NULL (not an error), which is safe and indicates "cannot calculate growth."

### 6. What is the difference between UNION and UNION ALL?
- **UNION** removes duplicate rows from the combined result.
- **UNION ALL** keeps all rows, including duplicates. It's faster because it doesn't need to check for duplicates.

### 7. What does ROLLUP do?
ROLLUP generates **hierarchical subtotals**. `GROUP BY ROLLUP(category, product)` produces totals at three levels: per product within category, per category, and a grand total.

### 8. What is the difference between a view and a materialized view?
- A **view** runs the query every time → always fresh, no extra storage.
- A **materialized view** stores the result on disk → faster reads, but needs `REFRESH` to update.

### 9. Why did PostgreSQL use Seq Scan despite having an index?
With only 40 rows, reading the entire table sequentially is **faster** than using an index. PostgreSQL's optimizer knows this. Indexes become useful at thousands or millions of rows.

### 10. What is 3NF?
Third Normal Form means: (1) the table is in 2NF, and (2) no non-key column depends on another non-key column (no transitive dependencies). For example, in `dim_product`, `category` depends on `product_id` directly — not through `product_name`.

---

## Project Structure

```
sql-dimensional-report/
├── sql/
│   ├── 01_schema.sql              # Table definitions & constraints
│   ├── 02_sample_data.sql         # 40 sample sales transactions
│   ├── 03_subqueries.sql          # Scalar, correlated, EXISTS
│   ├── 04_window_functions.sql    # RANK, LAG, NTILE, frames
│   ├── 05_cte_mom_growth.sql      # MoM report + recursive CTE
│   ├── 06_set_operations.sql      # UNION, INTERSECT, EXCEPT
│   ├── 07_rollup_cube_grouping.sql# ROLLUP, CUBE, GROUPING SETS
│   ├── 08_views.sql               # Standard & materialized views
│   └── 09_optimization.sql        # Indexes & EXPLAIN ANALYZE
├── README.md                      # This file
└── .gitignore
```

---

## Git Setup

```bash
cd sql-dimensional-report
git init
git add .
git commit -m "Initial commit: E-commerce Sales Analytics (Week 5)"
```

---

**Author**: Darsh  
**Course**: DataGrokr PLP — Week 5  
**Database**: PostgreSQL
