-- Test Group 1. No duplicates.

-- Dates

SELECT
    full_date,
    COUNT(*)
FROM bl_3nf.ce_dates
GROUP BY full_date
HAVING COUNT(*) > 1;

-- Geographies

SELECT
    country,
    city,
    source_system,
    source_entity,
    COUNT(*)
FROM bl_3nf.ce_geographies
GROUP BY
    country,
    city,
    source_system,
    source_entity
HAVING COUNT(*) > 1;

-- Customers

SELECT
    customer_src_id,
    source_system,
    source_entity,
    COUNT(*)
FROM bl_3nf.ce_customers
GROUP BY
    customer_src_id,
    source_system,
    source_entity
HAVING COUNT(*) > 1;

-- Employees

SELECT
    employee_src_id,
    source_system,
    source_entity,
    COUNT(*)
FROM bl_3nf.ce_employees
GROUP BY
    employee_src_id,
    source_system,
    source_entity
HAVING COUNT(*) > 1;
-- Stores

SELECT
    store_src_id,
    source_system,
    source_entity,
    COUNT(*)
FROM bl_3nf.ce_stores
GROUP BY
    store_src_id,
    source_system,
    source_entity
HAVING COUNT(*) > 1;

-- sales

SELECT
    sales_src_id,
    source_system,
    source_entity,
    COUNT(*)
FROM bl_3nf.ce_sales
GROUP BY
    sales_src_id,
    source_system,
    source_entity
HAVING COUNT(*) > 1;

-- Dim_Customers

SELECT
    customer_src_id,
    COUNT(*) AS duplicate_count
FROM bl_dm.dim_customer
GROUP BY customer_src_id
HAVING COUNT(*) > 1;

-- dim_employee

SELECT
    employee_src_id,
    COUNT(*) AS duplicate_count
FROM bl_dm.dim_employee
GROUP BY employee_src_id
HAVING COUNT(*) > 1;

-- dim_store

SELECT
    store_src_id,
    COUNT(*) AS duplicate_count
FROM bl_dm.dim_store
GROUP BY store_src_id
HAVING COUNT(*) > 1;

-- dim_time_day

SELECT
    event_dt,
    COUNT(*) AS duplicate_count
FROM bl_dm.dim_time_day
GROUP BY event_dt
HAVING COUNT(*) > 1;

-- fct sales

SELECT
    customer_surr_id,
    product_surr_id,
    store_surr_id,
    employee_surr_id,
    date_surr_id,
    COUNT(*) AS duplicate_count
FROM bl_dm.fct_sales_dd
GROUP BY
    customer_surr_id,
    product_surr_id,
    store_surr_id,
    employee_surr_id,
    date_surr_id
HAVING COUNT(*) > 1;



-- Test Group 2 SA -> BL validation

-- Customers

SELECT COUNT(*) AS missing_customers
FROM (
    SELECT DISTINCT customerid
    FROM sa_online_sales.src_online_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_customers c
    WHERE c.customer_src_id = s.customerid
      AND c.source_system = 'ONLINE'
      AND c.source_entity = 'src_online_sales'
);


SELECT COUNT(*) AS missing_customers
FROM (
    SELECT DISTINCT customerid
    FROM sa_store_sales.src_store_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_customers c
    WHERE c.customer_src_id = s.customerid
      AND c.source_system = 'STORE'
      AND c.source_entity = 'src_store_sales'
);


-- Products

SELECT COUNT(*) AS missing_products
FROM (
    SELECT DISTINCT productid
    FROM sa_online_sales.src_online_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_products_scd p
    WHERE p.product_src_id = s.productid
      AND p.source_system = 'ONLINE'
      AND p.source_entity = 'src_online_sales'
);

SELECT COUNT(*) AS missing_products
FROM (
    SELECT DISTINCT productid
    FROM sa_store_sales.src_store_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_products_scd p
    WHERE p.product_src_id = s.productid
      AND p.source_system = 'STORE'
      AND p.source_entity = 'src_store_sales'
);

-- Store

SELECT COUNT(*) AS missing_stores
FROM (
    SELECT DISTINCT storeid
    FROM sa_store_sales.src_store_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_stores st
    WHERE st.store_src_id = s.storeid
      AND st.source_system = 'STORE'
      AND st.source_entity = 'src_store_sales'
);

-- Employees

SELECT COUNT(*) AS missing_employees
FROM (
    SELECT DISTINCT employeeid
    FROM sa_store_sales.src_store_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_employees e
    WHERE e.employee_src_id = s.employeeid
      AND e.source_system = 'STORE'
      AND e.source_entity = 'src_store_sales'
);

-- Geographies

SELECT COUNT(*) AS missing_geographies
FROM (
    SELECT DISTINCT country, city
    FROM sa_online_sales.src_online_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_geographies g
    WHERE g.country = s.country
      AND g.city = s.city
      AND g.source_system = 'CUSTOMERS'
      AND g.source_entity = 'src_online_sales'
);


SELECT COUNT(*) AS missing_geographies
FROM (
    SELECT DISTINCT country, city
    FROM sa_store_sales.src_store_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_geographies g
    WHERE g.country = s.country
      AND g.city = s.city
      AND g.source_system = 'STORES'
      AND g.source_entity = 'src_store_sales'
);

-- Dates

SELECT COUNT(*) AS missing_dates
FROM (
    SELECT DISTINCT orderdate AS event_date
    FROM sa_online_sales.src_online_sales

    UNION

    SELECT DISTINCT saledate AS event_date
    FROM sa_store_sales.src_store_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_dates d
    WHERE d.full_date = s.orderdate
);

-- Sales

SELECT COUNT(*) AS missing_sales
FROM (
    SELECT DISTINCT onlineorderid
    FROM sa_online_sales.src_online_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_sales cs
    WHERE cs.sales_src_id = s.onlineorderid
      AND cs.source_system = 'ONLINE'
      AND cs.source_entity = 'src_online_sales'
);



SELECT COUNT(*) AS missing_sales
FROM (
    SELECT DISTINCT receiptid
    FROM sa_store_sales.src_store_sales
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_sales cs
    WHERE cs.sales_src_id = s.receiptid
      AND cs.source_system = 'STORE'
      AND cs.source_entity = 'src_store_sales'
);