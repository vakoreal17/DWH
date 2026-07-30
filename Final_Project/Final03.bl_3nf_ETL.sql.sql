CREATE SCHEMA IF NOT EXISTS bl_cl;

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_dates()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER;
begin

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
GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.log_etl(
    'load_ce_dates',
    'ONLINE,STORE',
    'SRC_ONLINE_SALES,SRC_STORE_SALES',
    'CE_DATES',
    v_rows_affected,
    'Load completed successfully.'
);
EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
		    'load_ce_dates',
		    'ONLINE,STORE',
		    'SRC_ONLINE_SALES,SRC_STORE_SALES',
		    'CE_DATES',
		    0,
		    SQLERRM
		);

        RAISE;

END;
$$;



CREATE OR REPLACE PROCEDURE bl_cl.load_ce_geographies()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER;
BEGIN

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
            customerid::varchar AS geo_src_id
        FROM sa_online_sales.src_online_sales

        UNION

        -------------------------------------------------
        -- Store Customers
        -------------------------------------------------

        SELECT DISTINCT
            COALESCE(customercountry,'n.a.'),
            COALESCE(customercity,'n.a.'),
            'STORE',
            'CUSTOMERS',
            customerid::varchar
        FROM sa_store_sales.src_store_sales

        UNION

        -------------------------------------------------
        -- Stores
        -------------------------------------------------

        SELECT DISTINCT
            COALESCE(storecountry,'n.a.'),
            COALESCE(storecity,'n.a.'),
            'STORE',
            'STORES',
            storeid::varchar
        FROM sa_store_sales.src_store_sales

    ) src

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM bl_3nf.ce_geographies g
        WHERE g.source_system = src.source_system
         	AND g.geo_src_id = src.geo_src_id
			AND g.source_entity = src.source_entity
    );

GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.log_etl(
    'load_ce_geographies',
    'ONLINE,STORE',
    'CUSTOMERS,STORES',
    'CE_GEOGRAPHIES',
    v_rows_affected,
    'Load completed successfully.'
);

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
		    'load_ce_geographies',
		    'ONLINE,STORE',
		    'CUSTOMERS,STORES',
		    'CE_GEOGRAPHIES',
		    0,
		    SQLERRM
		);

        RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_customers()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER;
BEGIN


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
            birthdate AS birth_date,
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
            birthdate AS birth_date,
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
			AND c.source_entity = src.source_entity
    );

GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.log_etl(
    'load_ce_customers',
    'ONLINE,STORE',
    'CUSTOMERS',
    'CE_CUSTOMERS',
    v_rows_affected,
    'Load completed successfully.'
);

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
		    'load_ce_customers',
		    'ONLINE,STORE',
		    'CUSTOMERS',
		    'CE_CUSTOMERS',
		    0,
		    SQLERRM
		);

        RAISE;

END;
$$;

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_products_scd()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER;
begin
	
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

        ---------------------------------------------
        -- STORE
        ---------------------------------------------
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
            'STORE' AS source_system,
            'PRODUCTS'AS source_entity
        FROM sa_store_sales.src_store_sales
    ) src

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM bl_3nf.ce_products_scd p
        WHERE p.product_src_id = src.product_src_id
         	AND p.source_system = src.source_system
			AND p.source_entity = src.source_entity
    );

    UPDATE bl_3nf.ce_products_scd p
    SET
        end_dt = CURRENT_DATE - INTERVAL '1 day',
        is_active = FALSE
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

    WHERE p.product_src_id = src.product_src_id
	    AND p.source_system = src.source_system
		AND p.source_entity = src.source_entity
	    AND p.is_active = TRUE
	    AND
      (
           COALESCE(p.product_name,'') <> COALESCE(src.product_name,'')
        OR COALESCE(p.brand,'') <> COALESCE(src.brand,'')
        OR COALESCE(p.category,'') <> COALESCE(src.category,'')
        OR COALESCE(p.subcategory,'') <> COALESCE(src.subcategory,'')
        OR COALESCE(p.color,'') <> COALESCE(src.color,'')
        OR COALESCE(p.size,'') <> COALESCE(src.size,'')
        OR COALESCE(p.unit_price,0) <> COALESCE(src.unit_price,0)
        OR COALESCE(p.unit_cost,0) <> COALESCE(src.unit_cost,0)
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
		    'PRODUCTS' AS source_entity,
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
		WHERE NOT EXISTS
		(
		    SELECT 1
		    FROM bl_3nf.ce_products_scd p
		    WHERE p.product_src_id = src.product_src_id
		    AND p.source_system = src.source_system
			AND p.source_entity = src.source_entity
		    AND p.is_active = TRUE
			AND p.end_dt = DATE '9999-12-31'

		);

GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.log_etl(
    'load_ce_products_scd',
    'ONLINE,STORE',
    'PRODUCTS',
    'CE_PRODUCTS_SCD',
    v_rows_affected,
    'Load completed successfully.'
);

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
		    'load_ce_products_scd',
		    'ONLINE,STORE',
		    'PRODUCTS',
		    'CE_PRODUCTS_SCD',
		    0,
		    SQLERRM
		);

        RAISE;		

END;
$$;


CREATE OR REPLACE PROCEDURE bl_cl.load_ce_stores()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER;
BEGIN

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

GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.log_etl(
    'load_ce_stores',
    'STORE',
    'STORES',
    'CE_STORES',
    v_rows_affected,
    'Load completed successfully.'
);

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
		    'load_ce_stores',
		    'STORE',
		    'STORES',
		    'CE_STORES',
		    0,
		    SQLERRM
		);

        RAISE;

END;
$$;


CREATE OR REPLACE PROCEDURE bl_cl.load_ce_employees()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER;
BEGIN

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

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM bl_3nf.ce_employees e
        WHERE e.employee_src_id = src.employee_src_id
         	AND e.source_system = src.source_system
			AND e.source_entity = src.source_entity
    );

GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.log_etl(
    'load_ce_employees',
    'STORE',
    'EMPLOYEES',
    'CE_EMPLOYEES',
    v_rows_affected,
    'Load completed successfully.'
);

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
		    'load_ce_employees',
		    'STORE',
		    'EMPLOYEES',
		    'CE_EMPLOYEES',
		    0,
		    SQLERRM
		);

        RAISE;

END;
$$;

-- Loop


CREATE OR REPLACE PROCEDURE bl_cl.load_all_3nf()
LANGUAGE plpgsql
AS
$$
DECLARE
    proc_name TEXT;
BEGIN

    FOR proc_name IN
        SELECT procedure_name
        FROM
        (
            VALUES
                ('load_ce_dates'),
                ('load_ce_geographies'),
                ('load_ce_customers'),
                ('load_ce_stores'),
                ('load_ce_employees'),
                ('load_ce_products_scd')
        ) p(procedure_name)

    LOOP

        EXECUTE format('CALL bl_cl.%I()', proc_name);

    END LOOP;

END;
$$;

CREATE OR REPLACE FUNCTION bl_cl.get_products()
RETURNS TABLE
(
    product_src_id VARCHAR,
    product_code VARCHAR,
    product_name VARCHAR,
    brand VARCHAR,
    category VARCHAR,
    subcategory VARCHAR,
    color VARCHAR,
    size VARCHAR,
    unit_price NUMERIC,
    unit_cost NUMERIC,
    source_system VARCHAR,
    source_entity VARCHAR
)
LANGUAGE plpgsql
AS
$$
BEGIN

    RETURN QUERY

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
        'ONLINE',
        'PRODUCTS'
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
        'STORE',
        'PRODUCTS'
    FROM sa_store_sales.src_store_sales;

END;
$$;


CREATE OR REPLACE PROCEDURE bl_cl.load_ce_sales()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER := 0;
    v_inserted INTEGER;
BEGIN
INSERT INTO bl_3nf.ce_sales
(
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
    sales_src_id,
    source_system,
    source_entity,
    payment_method,
    channel,
    insert_dt,
    update_dt
)
SELECT
    c.customer_id,
    p.product_id,
    -1,
    NULL,
    d.date_id,
    g.geo_id,
    s.quantity,
    s.unitprice,
    s.unitcost,
    s.salesamount,
    s.costamount,
    s.discountamount,
    s.onlineorderid,
    'ONLINE',
    'src_online_sales',
    s.paymentmethod,
    s.saleschannel,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM sa_online_sales.src_online_sales s

JOIN bl_3nf.ce_customers c
    ON c.customer_src_id = s.customerid
   AND c.source_system = 'ONLINE'
   AND c.source_entity = 'src_online_sales'

JOIN bl_3nf.ce_products_scd p
    ON p.product_src_id = s.productid
   AND p.source_system = 'ONLINE'
   AND p.source_entity = 'src_online_sales'
   AND p.is_active = TRUE

JOIN bl_3nf.ce_dates d
    ON d.full_date = s.orderdate

JOIN bl_3nf.ce_geographies g
    ON g.city = s.customercity
   AND g.country = s.customercountry
   AND g.source_system = 'CUSTOMERS'
   

WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_sales cs
    WHERE cs.sales_src_id = s.onlineorderid
      AND cs.source_system = 'ONLINE'
      AND cs.source_entity = 'src_online_sales'
);

GET DIAGNOSTICS v_inserted = ROW_COUNT;
v_rows_affected := v_rows_affected + v_inserted;

INSERT INTO bl_3nf.ce_sales
(
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
    sales_src_id,
    source_system,
    source_entity,
    payment_method,
    channel,
    insert_dt,
    update_dt
)
SELECT
    c.customer_id,
    p.product_id,
    st.store_id,
    e.employee_id,
    d.date_id,
    g.geo_id,
    s.quantity,
    s.unitprice,
    s.unitcost,
    s.salesamount,
    s.costamount,
    s.discountamount,
    s.receiptid,
    'STORE',
    'src_store_sales',
    s.paymentmethod,
    s.saleschannel,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM sa_store_sales.src_store_sales s

JOIN bl_3nf.ce_customers c
    ON c.customer_src_id = s.customerid
   AND c.source_system = 'STORE'
   AND c.source_entity = 'src_store_sales'

JOIN bl_3nf.ce_products_scd p
    ON p.product_src_id = s.productid
   AND p.source_system = 'STORE'
   AND p.source_entity = 'src_store_sales'
   AND p.is_active = TRUE

JOIN bl_3nf.ce_stores st
    ON st.store_src_id = s.storeid
    AND st.source_system = 'STORE'
    AND st.source_entity = 'src_store_sales'

LEFT JOIN bl_3nf.ce_employees e
    ON e.employee_src_id = s.employeeid
    AND e.source_system = 'STORE'
    AND e.source_entity = 'src_store_sales'

JOIN bl_3nf.ce_dates d
    ON d.full_date = s.saledate

JOIN bl_3nf.ce_geographies g
    ON g.city = s.storecity
   AND g.country = s.storecountry
   AND g.source_system = 'STORES'

WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_sales cs
    WHERE cs.sales_src_id = s.receiptid
      AND cs.source_system = 'STORE'
      AND cs.source_entity = 'src_store_sales'
);

GET DIAGNOSTICS v_inserted = ROW_COUNT;
v_rows_affected := v_rows_affected + v_inserted;

    RAISE NOTICE 'Loading CE_SALES...';

    CALL bl_cl.log_etl
    (
        'load_ce_sales',
        v_rows_affected,
        'CE_SALES loaded successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl
        (
            'load_ce_sales',
            0,
            SQLERRM
        );

        RAISE;

END;
$$;


-- Task 2 Logging table

CREATE SEQUENCE IF NOT EXISTS bl_cl.seq_etl_log
START WITH 1
INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS bl_cl.etl_log
(
    log_id BIGINT PRIMARY KEY
        DEFAULT nextval('bl_cl.seq_etl_log'),

    log_datetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    procedure_name VARCHAR(100) NOT NULL,

    rows_affected INTEGER NOT NULL,

    log_message TEXT NOT NULL
);

ALTER TABLE bl_cl.etl_log
ADD COLUMN IF NOT EXISTS source_system VARCHAR(100);

ALTER TABLE bl_cl.etl_log
ADD COLUMN IF NOT EXISTS source_entity VARCHAR(100);

ALTER TABLE bl_cl.etl_log
ADD COLUMN IF NOT EXISTS target_table VARCHAR(100);

CREATE OR REPLACE PROCEDURE bl_cl.log_etl
(
    p_procedure_name VARCHAR,
    p_source_system VARCHAR,
    p_source_entity VARCHAR,
    p_target_table VARCHAR,
    p_rows_affected INTEGER,
    p_log_message TEXT
)
LANGUAGE plpgsql
AS
$$
BEGIN

    INSERT INTO bl_cl.etl_log
	(
    procedure_name,
    source_system,
    source_entity,
    target_table,
    rows_affected,
    log_message
	)
	VALUES
	(
	    p_procedure_name,
	    p_source_system,
	    p_source_entity,
	    p_target_table,
	    p_rows_affected,
	    p_log_message
	);

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION
            'log_etl failed: %',
            SQLERRM;

END;
$$;

-- Privileges
GRANT USAGE ON SCHEMA bl_3nf TO bl_cl;

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA bl_3nf
TO bl_cl;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA bl_3nf
TO bl_cl;
