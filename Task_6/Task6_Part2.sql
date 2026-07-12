INSERT INTO bl_3nf.ce_dates
(
    full_date,
    day,
    month,
    quarter,
    year
)

SELECT DISTINCT
       src.full_date,
       src.day,
       src.month,
       src.quarter,
       src.year
FROM
(
    SELECT
        orderdate AS full_date,
        day,
        month,
        quarter,
        year
    FROM sa_online_sales.src_online_sales

    UNION

    SELECT
        saledate,
        day,
        month,
        quarter,
        year
    FROM sa_store_sales.src_store_sales
) src
WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_dates d
    WHERE d.full_date = src.full_date
);

COMMIT;

INSERT INTO bl_3nf.ce_geographies
(
    country,
    city,
    source_system,
    source_entity,
    geo_src_id
)

SELECT
    src.country,
    src.city,
    src.source_system,
    src.source_entity,
    src.geo_src_id
FROM
(
    -------------------------------------------------
    -- Online Customers
    -------------------------------------------------

    SELECT DISTINCT

        COALESCE(customercountry,'n.a.') AS country,

        COALESCE(customercity,'n.a.') AS city,

        'ONLINE' AS source_system,

        'CUSTOMERS' AS source_entity,

        COALESCE(customercountry,'n.a.') || '_' ||
		COALESCE(customercity,'n.a.') AS geo_src_id

    FROM sa_online_sales.src_online_sales

    UNION ALL

    -------------------------------------------------
    -- Store Customers
    -------------------------------------------------

    SELECT DISTINCT

        COALESCE(customercountry,'n.a.'),

        COALESCE(customercity,'n.a.'),

        'STORE',

        'CUSTOMERS',

        COALESCE(customercountry,'n.a.') || '_' ||
		COALESCE(customercity,'n.a.')

    FROM sa_store_sales.src_store_sales

    UNION ALL

    -------------------------------------------------
    -- Stores
    -------------------------------------------------

    SELECT DISTINCT

        COALESCE(storecountry,'n.a.'),

        COALESCE(storecity,'n.a.'),

        'STORE',

        'STORES',

        COALESCE(storecountry,'n.a.') || '_' ||
		COALESCE(storecity,'n.a.')

    FROM sa_store_sales.src_store_sales

) src

WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_geographies g
    WHERE g.source_system = src.source_system
		AND g.source_entity = src.source_entity
		AND g.geo_src_id = src.geo_src_id
);

COMMIT;

INSERT INTO bl_3nf.ce_customers
(
    customer_src_id,
    first_name,
    last_name,
    gender,
    birth_date,
    email,
    country,
    city,
    source_system,
    source_entity
)

SELECT
    src.customer_src_id,
    src.first_name,
    src.last_name,
    src.gender,
    src.birth_date,
    src.email,
    src.country,
    src.city,
    src.source_system,
    src.source_entity
FROM
(
    --------------------------------------------------
    -- ONLINE
    --------------------------------------------------

    SELECT DISTINCT

        customerid::varchar AS customer_src_id,

        COALESCE(firstname,'n.a.') AS first_name,

        COALESCE(lastname,'n.a.') AS last_name,

        COALESCE(gender,'n.a.') AS gender,

        birthdate,

        COALESCE(email,'n.a.') AS email,

        COALESCE(customercountry,'n.a.') AS country,

        COALESCE(customercity,'n.a.') AS city,

        'ONLINE' AS source_system,

        'CUSTOMERS' AS source_entity

    FROM sa_online_sales.src_online_sales

    UNION

    --------------------------------------------------
    -- STORE
    --------------------------------------------------

    SELECT DISTINCT

        customerid::varchar,

        COALESCE(firstname,'n.a.'),

        COALESCE(lastname,'n.a.'),

        COALESCE(gender,'n.a.'),

        birthdate,

        COALESCE(email,'n.a.'),

        COALESCE(customercountry,'n.a.'),

        COALESCE(customercity,'n.a.'),

        'STORE',

        'CUSTOMERS'

    FROM sa_store_sales.src_store_sales

) src

WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_customers c
    WHERE c.customer_src_id = src.customer_src_id
      AND c.source_system = src.source_system
);

COMMIT;

INSERT INTO bl_3nf.ce_products_scd
(
    product_src_id,
    product_code,
    product_name,
    brand,
    category,
    subcategory,
    color,
    size,
    unit_price,
    unit_cost,
    source_system,
    source_entity,
    start_dt,
    end_dt,
    is_active
)
SELECT
    src.product_src_id,
    src.product_code,
    src.product_name,
    src.brand,
    src.category,
    src.subcategory,
    src.color,
    src.size,
    src.unit_price,
    src.unit_cost,
    src.source_system,
    src.source_entity,
    CURRENT_DATE,
    DATE '9999-12-31',
    TRUE
FROM
(
    ---------------------------------------------
    -- ONLINE
    ---------------------------------------------

    SELECT DISTINCT

        productid::varchar AS product_src_id,

        productcode,

        productname,

        brand,

        category,

        subcategory,

        color,

        size,

        unitprice,

        unitcost,

        'ONLINE' AS source_system,

        'PRODUCTS' AS source_entity

    FROM sa_online_sales.src_online_sales

    UNION

    ---------------------------------------------
    -- STORE
    ---------------------------------------------

    SELECT DISTINCT

        productid::varchar,

        productcode,

        productname,

        brand,

        category,

        subcategory,

        color,

        size,

        unitprice,

        unitcost,

        'STORE',

        'PRODUCTS'

    FROM sa_store_sales.src_store_sales

) src

WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_products_scd p
    WHERE p.product_src_id = src.product_src_id
      AND p.source_system = src.source_system
);

UPDATE bl_3nf.ce_products_scd p

SET

    end_dt = CURRENT_DATE - INTERVAL '1 day',

    is_active = FALSE

FROM
(
    SELECT DISTINCT

        productid::varchar AS product_src_id,

        productcode,

        productname,

        brand,

        category,

        subcategory,

        color,

        size,

        unitprice,

        unitcost,

        'ONLINE' AS source_system

    FROM sa_online_sales.src_online_sales

    UNION

    SELECT DISTINCT

        productid::varchar,

        productcode,

        productname,

        brand,

        category,

        subcategory,

        color,

        size,

        unitprice,

        unitcost,

        'STORE'

    FROM sa_store_sales.src_store_sales

) src

WHERE

    p.product_src_id = src.product_src_id

AND p.source_system = src.source_system

AND p.is_active = TRUE

AND
(
       COALESCE(p.product_name,'') <> COALESCE(src.productname,'')

    OR COALESCE(p.brand,'') <> COALESCE(src.brand,'')

    OR COALESCE(p.category,'') <> COALESCE(src.category,'')

    OR COALESCE(p.subcategory,'') <> COALESCE(src.subcategory,'')

    OR COALESCE(p.color,'') <> COALESCE(src.color,'')

    OR COALESCE(p.size,'') <> COALESCE(src.size,'')

    OR COALESCE(p.unit_price,0) <> COALESCE(src.unitprice,0)

    OR COALESCE(p.unit_cost,0) <> COALESCE(src.unitcost,0)
);

INSERT INTO bl_3nf.ce_products_scd
(
    product_src_id,
    product_code,
    product_name,
    brand,
    category,
    subcategory,
    color,
    size,
    unit_price,
    unit_cost,
    source_system,
    source_entity,
    start_dt,
    end_dt,
    is_active
)
SELECT

    src.product_src_id,

    src.product_code,

    src.product_name,

    src.brand,

    src.category,

    src.subcategory,

    src.color,

    src.size,

    src.unit_price,

    src.unit_cost,

    src.source_system,

    src.source_entity,

    CURRENT_DATE,

    DATE '9999-12-31',

    TRUE

FROM
(
    SELECT DISTINCT

        productid::varchar AS product_src_id,

        productcode AS product_code,

        productname AS product_name,

        brand,

        category,

        subcategory,

        color,

        size,

        unitprice AS unit_price,

        unitcost AS unit_cost,

        'ONLINE' AS source_system,
        
        'PRODUCTS' AS source_entity

    FROM sa_online_sales.src_online_sales

    UNION

    SELECT DISTINCT

        productid::varchar,

        productcode,

        productname,

        brand,

        category,

        subcategory,

        color,

        size,

        unitprice,

        unitcost,

        'STORE'
        
        'PRODUCTS'

    FROM sa_store_sales.src_store_sales

) src

WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_products_scd p
    WHERE p.product_src_id = src.product_src_id
      AND p.source_system = src.source_system
      AND p.source_entity = 'PRODUCTS'
      AND p.is_active = TRUE
      AND COALESCE(p.product_name,'') = COALESCE(src.product_name,'')
      AND COALESCE(p.brand,'') = COALESCE(src.brand,'')
      AND COALESCE(p.category,'') = COALESCE(src.category,'')
      AND COALESCE(p.subcategory,'') = COALESCE(src.subcategory,'')
      AND COALESCE(p.color,'') = COALESCE(src.color,'')
      AND COALESCE(p.size,'') = COALESCE(src.size,'')
      AND COALESCE(p.unit_price,0) = COALESCE(src.unit_price,0)
      AND COALESCE(p.unit_cost,0) = COALESCE(src.unit_cost,0)

COMMIT;

INSERT INTO bl_3nf.ce_stores
(
    store_src_id,
    store_name,
    address,
    geo_id,
    source_system,
    source_entity
)

SELECT

    src.store_src_id,

    src.store_name,

    src.address,

    g.geo_id,

    src.source_system,

    src.source_entity

FROM
(
    SELECT DISTINCT

        storeid::varchar AS store_src_id,

        COALESCE(storename,'n.a.') AS store_name,

        COALESCE(storeaddress,'n.a.') AS address,

        COALESCE(storecountry,'n.a.') AS country,

        COALESCE(storecity,'n.a.') AS city,

        'STORE' AS source_system,

        'STORES' AS source_entity

    FROM sa_store_sales.src_store_sales

) src

LEFT JOIN bl_3nf.ce_geographies g

       ON g.country = src.country
      AND g.city = src.city
      AND g.source_system = 'STORE'
      AND g.source_entity = 'STORES'

WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_stores s
    WHERE s.store_src_id = src.store_src_id
      AND s.source_system = src.source_system
      AND s.source_entity = src.source_entity
);

COMMIT;

INSERT INTO bl_3nf.ce_employees
(
    employee_src_id,
    first_name,
    last_name,
    position,
    store_id,
    source_system,
    source_entity
)

SELECT

    src.employee_src_id,

    split_part(src.employee_name,' ',1),

    CASE
        WHEN position(' ' IN src.employee_name) > 0
        THEN substring(src.employee_name FROM position(' ' IN src.employee_name)+1)
        ELSE NULL
    END,

    src.position,

    st.store_id,

    src.source_system,

    src.source_entity

FROM
(
    SELECT DISTINCT

        employeeid::varchar AS employee_src_id,

        COALESCE(employeename,'n.a.') AS employee_name,

        COALESCE(position,'n.a.') AS position,

        storeid::varchar AS store_src_id,

        'STORE' AS source_system,

        'EMPLOYEES' AS source_entity

    FROM sa_store_sales.src_store_sales

) src

LEFT JOIN bl_3nf.ce_stores st

       ON st.store_src_id = src.store_src_id
      AND st.source_system = 'STORE'
      AND st.source_entity = 'STORES'

WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_employees e
    WHERE e.employee_src_id = src.employee_src_id
      AND e.source_system = src.source_system
      AND e.source_entity = src.source_entity
);

COMMIT;

INSERT INTO bl_3nf.ce_sales
(
    sales_src_id,
    source_system,
    source_entity,
    customer_id,
    product_id,
    store_id,
    employee_id,
    date_id,
    geo_id,
    quantity,
    unit_price,
    unit_cost,
    sales_amount,
    cost_amount,
    discount_amount,
    payment_method,
    channel
)

SELECT
    src.sales_src_id,
    src.source_system,
    src.source_entity,
    c.customer_id,
    p.product_id,
    st.store_id,
    e.employee_id,
    d.date_id,
    g.geo_id,
    src.quantity,
    src.unit_price,
    src.unit_cost,
    src.sales_amount,
    src.cost_amount,
    src.discount_amount,
    src.payment_method,
    src.channel

FROM
(
    ----------------------------------------------------------
    -- ONLINE SALES
    ----------------------------------------------------------
    SELECT
        onlineorderid::VARCHAR AS sales_src_id,
        'ONLINE' AS source_system,
        'SALES' AS source_entity,

        customerid::VARCHAR AS customer_src_id,
        productid::VARCHAR AS product_src_id,

        NULL::VARCHAR AS store_src_id,
        NULL::VARCHAR AS employee_src_id,

        orderdate AS sales_date,

        customercountry AS country,
        customercity AS city,

        quantity,
        unitprice AS unit_price,
        unitcost,
        salesamount,
        costamount,
        discountamount,
        paymentmethod,
        saleschannel AS channel

    FROM sa_online_sales.src_online_sales

    UNION ALL

    ----------------------------------------------------------
    -- STORE SALES
    ----------------------------------------------------------
    SELECT
        receiptid::VARCHAR,
        'STORE',
        'SALES',

        customerid::VARCHAR,
        productid::VARCHAR,

        storeid::VARCHAR,
        employeeid::VARCHAR,

        saledate,

        storecountry,
        storecity,

        quantity,
        unitprice,
        unitcost,
        salesamount,
        costamount,
        discountamount,
        paymentmethod,
        saleschannel

    FROM sa_store_sales.src_store_sales

) src

LEFT JOIN bl_3nf.ce_customers c
       ON c.customer_src_id = src.customer_src_id
      AND c.source_system = src.source_system
      AND c.source_entity = 'CUSTOMERS'

LEFT JOIN bl_3nf.ce_products_scd p
       ON p.product_src_id = src.product_src_id
      AND p.source_system = src.source_system
      AND p.source_entity = 'PRODUCTS'
      AND p.is_active = TRUE

LEFT JOIN bl_3nf.ce_stores st
       ON st.store_src_id = src.store_src_id
      AND st.source_system = 'STORE'
      AND st.source_entity = 'STORES'

LEFT JOIN bl_3nf.ce_employees e
       ON e.employee_src_id = src.employee_src_id
      AND e.source_system = 'STORE'
      AND e.source_entity = 'EMPLOYEES'

LEFT JOIN bl_3nf.ce_dates d
       ON d.full_date = src.sales_date

LEFT JOIN bl_3nf.ce_geographies g
		ON g.country = COALESCE(src.country, 'n.a.')
		AND g.city = COALESCE(src.city, 'n.a.')
		AND g.source_system =
            CASE
                WHEN src.source_system = 'ONLINE'
                THEN 'ONLINE'
                ELSE 'STORE'
            END
		AND g.source_entity =
			CASE
				WHEN src.store_src_id IS NULL
				THEN 'CUSTOMERS'
				ELSE 'STORES'
			END

WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_sales s
    WHERE s.sales_src_id = src.sales_src_id
      AND s.source_system = src.source_system
      AND s.source_entity = src.source_entity
);

COMMIT;