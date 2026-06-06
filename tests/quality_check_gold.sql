/*

================================================================================
QUALITY CHECKS — GOLD LAYER
===========================

Script Purpose:

```
This script performs data validation checks for the Gold Layer.
```

Checks Included:

```
- Duplicate dimension keys
- Null keys
- Referential integrity
- Missing dimension references
- Invalid dates
- Sales consistency
- Standardized values
```

Expected Result:

```
Most validation queries should return:
→ 0 Rows
```

================================================================================

*/

-- =============================================================================
-- DIM_CUSTOMERS
-- =============================================================================

-- Check duplicate customer keys
SELECT
customer_key,
COUNT(*)
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check NULL customer keys
SELECT *
FROM gold.dim_customers
WHERE customer_key IS NULL;

-- Check invalid genders
SELECT DISTINCT gender
FROM gold.dim_customers;

-- Check invalid marital status
SELECT DISTINCT marital_status
FROM gold.dim_customers;

-- =============================================================================
-- DIM_PRODUCTS
-- =============================================================================

-- Check duplicate product keys
SELECT
product_key,
COUNT(*)
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Check NULL product keys
SELECT *
FROM gold.dim_products
WHERE product_key IS NULL;

-- Check negative product cost
SELECT *
FROM gold.dim_products
WHERE cost < 0;

-- Check category values
SELECT DISTINCT
category,
subcategory
FROM gold.dim_products;

-- =============================================================================
-- FACT_SALES
-- =============================================================================

-- Check NULL foreign keys
SELECT *
FROM gold.fact_sales
WHERE customer_key IS NULL
OR product_key IS NULL;

-- Check invalid date sequence
SELECT *
FROM gold.fact_sales
WHERE order_date > shipping_date
OR shipping_date > due_date;

-- Check sales consistency
SELECT *
FROM gold.fact_sales
WHERE sales_amount != quantity * price
OR sales_amount <= 0
OR quantity <= 0
OR price <= 0;

-- =============================================================================
-- REFERENTIAL INTEGRITY CHECKS
-- =============================================================================

-- Fact → Customer integrity
SELECT *
FROM gold.fact_sales f

LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key

WHERE c.customer_key IS NULL;

-- Fact → Product integrity
SELECT *
FROM gold.fact_sales f

LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key

WHERE p.product_key IS NULL;

-- =============================================================================
-- RECORD COUNT CHECKS
-- =============================================================================

SELECT COUNT(*) AS customers
FROM gold.dim_customers;

SELECT COUNT(*) AS products
FROM gold.dim_products;

SELECT COUNT(*) AS sales
FROM gold.fact_sales;

================================================================================

Expected Results:

Duplicate Checks      → 0 Rows
NULL Checks           → 0 Rows
Integrity Checks      → 0 Rows
Date Checks           → 0 Rows
Sales Checks          → 0 Rows

================================================================================
