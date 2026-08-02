CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_customer_surr_id
START WITH 1
INCREMENT BY 1
MINVALUE 1;

ALTER TABLE bl_dm.dim_customer
ALTER COLUMN customer_surr_id
SET DEFAULT nextval('bl_dm.seq_dim_customer_surr_id');

SELECT setval(
    'bl_dm.seq_dim_customer_surr_id',
    GREATEST(
        COALESCE(
            (SELECT MAX(customer_surr_id)
             FROM bl_dm.dim_customer
             WHERE customer_surr_id > 0),
            1
        ),
        1
    ),
    false
);

ALTER TABLE bl_dm.dim_customer
ADD CONSTRAINT uk_dim_customer_customer_src_id
UNIQUE(customer_src_id);

CREATE OR REPLACE PROCEDURE bl_cl.load_dim_customer()
LANGUAGE plpgsql
AS
$$
BEGIN

    INSERT INTO bl_dm.dim_customer
    (
        customer_surr_id,
        customer_src_id,
        first_name,
        last_name,
        gender,
        birth_date,
        email,
        phone,
        country_src_id,
        country,
        city_src_id,
        city,
        source_system,
        source_entity,
        insert_dt,
        update_dt
    )

    SELECT
        nextval('bl_dm.seq_dim_customer_surr_id'),
        c.customer_src_id,
        c.first_name,
        c.last_name,
        c.gender,
        c.birth_date,
        c.email,
        'n.a.',
        g.geo_src_id,
        c.country,
        g.geo_src_id,
        c.city,
        c.source_system,
        c.source_entity,
        CURRENT_DATE,
        CURRENT_DATE

    FROM bl_3nf.ce_customers c

    LEFT JOIN bl_3nf.ce_geographies g
           ON c.country = g.country
          AND c.city = g.city

    WHERE c.customer_src_id <> -1

    ON CONFLICT (customer_src_id)
    DO UPDATE
    SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        gender = EXCLUDED.gender,
        birth_date = EXCLUDED.birth_date,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        country_src_id = EXCLUDED.country_src_id,
        country = EXCLUDED.country,
        city_src_id = EXCLUDED.city_src_id,
        city = EXCLUDED.city,
        update_dt = CURRENT_DATE;

END;
$$;

ALTER TABLE bl_dm.dim_customer
ADD CONSTRAINT uk_dim_customer_customer_src_id
UNIQUE (customer_src_id);

CREATE OR REPLACE PROCEDURE bl_cl.load_dim_customer()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER := 0;
BEGIN

    MERGE INTO bl_dm.dim_customer AS tgt
    USING
    (
        SELECT DISTINCT ON (c.customer_src_id)
            c.customer_src_id,
            c.first_name,
            c.last_name,
            c.gender,
            c.birth_date,
            c.email,
            'n.a.'::varchar AS phone,
            g.geo_id AS country_src_id,
            c.country,
            g.geo_id AS city_src_id,
            c.city,
            c.source_system,
            c.source_entity,
            COALESCE(c.insert_dt::date, CURRENT_DATE) AS insert_dt,
			COALESCE(c.update_dt::date, CURRENT_DATE) AS update_dt
        FROM bl_3nf.ce_customers c
        LEFT JOIN
        (
            SELECT
                country,
                city,
                MIN(geo_id) AS geo_id
            FROM bl_3nf.ce_geographies
            GROUP BY country, city
        ) g
          ON c.country = g.country
         AND c.city = g.city
        WHERE c.customer_src_id <> '-1'
        ORDER BY c.customer_src_id, c.customer_id
    ) AS src

    ON tgt.customer_src_id = src.customer_src_id

    WHEN MATCHED THEN
        UPDATE SET
            first_name     = src.first_name,
            last_name      = src.last_name,
            gender         = src.gender,
            birth_date     = src.birth_date,
            email          = src.email,
            phone          = src.phone,
            country_src_id = src.country_src_id,
            country        = src.country,
            city_src_id    = src.city_src_id,
            city           = src.city,
            source_system  = src.source_system,
            source_entity  = src.source_entity,
            update_dt      = src.update_dt

    WHEN NOT MATCHED THEN
        INSERT
        (
            customer_surr_id,
            customer_src_id,
            first_name,
            last_name,
            gender,
            birth_date,
            email,
            phone,
            country_src_id,
            country,
            city_src_id,
            city,
            source_system,
            source_entity,
            insert_dt,
            update_dt
        )
        VALUES
        (
            nextval('bl_dm.seq_dim_customer_surr_id'),
            src.customer_src_id,
            src.first_name,
            src.last_name,
            src.gender,
            src.birth_date,
            src.email,
            src.phone,
            src.country_src_id,
            src.country,
            src.city_src_id,
            src.city,
            src.source_system,
            src.source_entity,
            src.insert_dt,
            src.update_dt
        );

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    CALL bl_cl.log_etl(
        'load_dim_customer',
        v_rows_affected,
        'DIM_CUSTOMER loaded successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
            'load_dim_customer',
            0,
            SQLERRM
        );

        RAISE;
END;
$$;

CALL bl_cl.load_dim_customer();

SELECT COUNT(*)
FROM bl_dm.dim_customer;

SELECT *
FROM bl_cl.etl_log
WHERE procedure_name = 'load_dim_customer'
ORDER BY log_id desc
limit 2;

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_employee_surr_id
START WITH 1
INCREMENT BY 1
MINVALUE 1;

ALTER TABLE bl_dm.dim_employee
ALTER COLUMN employee_surr_id
SET DEFAULT nextval('bl_dm.seq_dim_employee_surr_id');

SELECT setval(
    'bl_dm.seq_dim_employee_surr_id',
    GREATEST(
        COALESCE(
            (SELECT MAX(employee_surr_id)
             FROM bl_dm.dim_employee
             WHERE employee_surr_id > 0),
            1
        ),
        1
    ),
    false
);

ALTER TABLE bl_dm.dim_employee
ADD CONSTRAINT uk_dim_employee_employee_src_id
UNIQUE (employee_src_id);

CREATE OR REPLACE PROCEDURE bl_cl.load_dim_employee()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER := 0;
BEGIN

    MERGE INTO bl_dm.dim_employee AS tgt
    USING
    (
        SELECT
            e.employee_src_id,
            e.first_name,
            e.last_name,
            e.position,

            s.store_id AS store_src_id,
            s.store_name,

            COALESCE(g.geo_id, -1) AS city_src_id,
			COALESCE(g.city, 'Unknown') AS city,

            COALESCE(g.geo_id, -1) AS country_src_id,
			COALESCE(g.country, 'Unknown') AS country,

            e.source_system,
            e.source_entity,

            COALESCE(e.insert_dt::date, CURRENT_DATE) AS insert_dt,
            COALESCE(e.update_dt::date, CURRENT_DATE) AS update_dt

        FROM bl_3nf.ce_employees e

        INNER JOIN bl_3nf.ce_stores s
            ON e.store_id = s.store_id

        LEFT JOIN bl_3nf.ce_geographies g
            ON s.geo_id = g.geo_id

        WHERE e.employee_src_id <> '-1'

    ) AS src

    ON tgt.employee_src_id = src.employee_src_id

    WHEN MATCHED THEN
        UPDATE
        SET
            first_name      = src.first_name,
            last_name       = src.last_name,
            position        = src.position,
            store_src_id    = src.store_src_id,
            store_name      = src.store_name,
            city_src_id     = src.city_src_id,
            city            = src.city,
            country_src_id  = src.country_src_id,
            country         = src.country,
            source_system   = src.source_system,
            source_entity   = src.source_entity,
            update_dt       = src.update_dt

    WHEN NOT MATCHED THEN
        INSERT
        (
            employee_surr_id,
            employee_src_id,
            first_name,
            last_name,
            position,
            store_src_id,
            store_name,
            city_src_id,
            city,
            country_src_id,
            country,
            source_system,
            source_entity,
            insert_dt,
            update_dt
        )
        VALUES
        (
            nextval('bl_dm.seq_dim_employee_surr_id'),
            src.employee_src_id,
            src.first_name,
            src.last_name,
            src.position,
            src.store_src_id,
            src.store_name,
            src.city_src_id,
            src.city,
            src.country_src_id,
            src.country,
            src.source_system,
            src.source_entity,
            src.insert_dt,
            src.update_dt
        );

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    CALL bl_cl.log_etl(
        'load_dim_employee',
        v_rows_affected,
        'DIM_EMPLOYEE loaded successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
            'load_dim_employee',
            0,
            SQLERRM
        );

        RAISE;

END;
$$;

CALL bl_cl.load_dim_employee();

SELECT COUNT(*)
FROM bl_dm.dim_employee;

SELECT *
FROM bl_dm.dim_employee
LIMIT 10;

SELECT *
FROM bl_cl.etl_log
WHERE procedure_name = 'load_dim_employee'
ORDER BY log_id DESC;

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_store_surr_id
START WITH 1
INCREMENT BY 1
MINVALUE 1;

ALTER TABLE bl_dm.dim_store
ALTER COLUMN store_surr_id
SET DEFAULT nextval('bl_dm.seq_dim_store_surr_id');

SELECT setval(
    'bl_dm.seq_dim_store_surr_id',
    GREATEST(
        COALESCE(
            (SELECT MAX(store_surr_id)
             FROM bl_dm.dim_store
             WHERE store_surr_id > 0),
            1
        ),
        1
    ),
    false
);

ALTER TABLE bl_dm.dim_store
ADD CONSTRAINT uk_dim_store_store_src_id
UNIQUE (store_src_id);


CREATE OR REPLACE PROCEDURE bl_cl.load_dim_store()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER := 0;

    rec_store RECORD;

    cur_store CURSOR FOR
        SELECT
            s.store_src_id,
            s.store_name,
            s.address,

            g.geo_id AS city_src_id,
            g.city,

            g.geo_id AS country_src_id,
            g.country,

            s.source_system,
            s.source_entity,

            COALESCE(s.insert_dt::date, CURRENT_DATE) AS insert_dt,
            COALESCE(s.update_dt::date, CURRENT_DATE) AS update_dt

        FROM bl_3nf.ce_stores s
        INNER JOIN bl_3nf.ce_geographies g
            ON s.geo_id = g.geo_id
        WHERE s.store_src_id <> '-1';

BEGIN

    FOR rec_store IN cur_store
    LOOP

        IF EXISTS
        (
            SELECT 1
            FROM bl_dm.dim_store d
            WHERE d.store_src_id = rec_store.store_src_id
        )
        THEN

            UPDATE bl_dm.dim_store
            SET
                store_name     = rec_store.store_name,
                address        = rec_store.address,
                city_src_id    = rec_store.city_src_id,
                city           = rec_store.city,
                country_src_id = rec_store.country_src_id,
                country        = rec_store.country,
                source_system  = rec_store.source_system,
                source_entity  = rec_store.source_entity,
                update_dt      = rec_store.update_dt
            WHERE store_src_id = rec_store.store_src_id;

        ELSE

            INSERT INTO bl_dm.dim_store
            (
                store_surr_id,
                store_src_id,
                store_name,
                address,
                city_src_id,
                city,
                country_src_id,
                country,
                source_system,
                source_entity,
                insert_dt,
                update_dt
            )
            VALUES
            (
                nextval('bl_dm.seq_dim_store_surr_id'),
                rec_store.store_src_id,
                rec_store.store_name,
                rec_store.address,
                rec_store.city_src_id,
                rec_store.city,
                rec_store.country_src_id,
                rec_store.country,
                rec_store.source_system,
                rec_store.source_entity,
                rec_store.insert_dt,
                rec_store.update_dt
            );

        END IF;

        v_rows_affected := v_rows_affected + 1;

    END LOOP;

    CALL bl_cl.log_etl
    (
        'load_dim_store',
        v_rows_affected,
        'DIM_STORE loaded successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl
        (
            'load_dim_store',
            0,
            SQLERRM
        );

        RAISE;

END;
$$;

CALL bl_cl.load_dim_store();

SELECT COUNT(*)
FROM bl_dm.dim_store;

SELECT *
FROM bl_cl.etl_log
WHERE procedure_name='load_dim_store'
ORDER BY log_id DESC;

-- Dim_time_day

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_time_day_surr_id
START WITH 1
INCREMENT BY 1
MINVALUE 1;

ALTER TABLE bl_dm.dim_time_day
ALTER COLUMN date_surr_id
SET DEFAULT nextval('bl_dm.seq_dim_time_day_surr_id');

SELECT setval(
    'bl_dm.seq_dim_time_day_surr_id',
    GREATEST(
        COALESCE(
            (SELECT MAX(date_surr_id)
             FROM bl_dm.dim_time_day
             WHERE date_surr_id > 0),
            1
        ),
        1
    ),
    false
);

CREATE OR REPLACE PROCEDURE bl_cl.load_dim_time_day()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER := 0;
BEGIN

    MERGE INTO bl_dm.dim_time_day AS tgt
    USING
    (
        SELECT
            full_date AS event_dt,
            day,
            month,
            TO_CHAR(full_date, 'Month')::varchar AS month_name,
            quarter,
            year,
            EXTRACT(ISODOW FROM full_date)::smallint AS day_of_week,
            CASE
                WHEN EXTRACT(ISODOW FROM full_date) IN (6,7)
                THEN 'Y'
                ELSE 'N'
            END AS weekend_flag
        FROM bl_3nf.ce_dates
    ) src

    ON tgt.event_dt = src.event_dt

    WHEN MATCHED THEN
        UPDATE
        SET
            day          = src.day,
            month        = src.month,
            month_name   = src.month_name,
            quarter      = src.quarter,
            year         = src.year,
            day_of_week  = src.day_of_week,
            weekend_flag = src.weekend_flag

    WHEN NOT MATCHED THEN
        INSERT
        (
            date_surr_id,
            event_dt,
            day,
            month,
            month_name,
            quarter,
            year,
            day_of_week,
            weekend_flag
        )
        VALUES
        (
            nextval('bl_dm.seq_dim_time_day_surr_id'),
            src.event_dt,
            src.day,
            src.month,
            src.month_name,
            src.quarter,
            src.year,
            src.day_of_week,
            src.weekend_flag
        );

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    CALL bl_cl.log_etl(
        'load_dim_time_day',
        v_rows_affected,
        'DIM_TIME_DAY loaded successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
            'load_dim_time_day',
            0,
            SQLERRM
        );

        RAISE;
END;
$$;

CALL bl_cl.load_dim_time_day();

SELECT COUNT(*)
FROM bl_dm.dim_time_day;

SELECT *
FROM bl_cl.etl_log
WHERE procedure_name='load_dim_time_day'
ORDER BY log_id DESC;

-- dim_products_scd

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_product_surr_id
START WITH 1
INCREMENT BY 1
MINVALUE 1;

ALTER TABLE bl_dm.dim_products_scd
ALTER COLUMN product_surr_id
SET DEFAULT nextval('bl_dm.seq_dim_product_surr_id');

SELECT setval(
    'bl_dm.seq_dim_product_surr_id',
    GREATEST(
        COALESCE(
            (
                SELECT MAX(product_surr_id)
                FROM bl_dm.dim_products_scd
                WHERE product_surr_id > 0
            ),
            1
        ),
        1
    ),
    false
);


CREATE OR REPLACE PROCEDURE bl_cl.load_dim_products_scd()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER := 0;

BEGIN

    ------------------------------------------------------------------
    -- Expire changed active records
    ------------------------------------------------------------------

    UPDATE bl_dm.dim_products_scd d
       SET end_dt = CURRENT_DATE - 1,
           is_active = 'N'
    FROM
    (
        SELECT DISTINCT ON (product_src_id)
               *
        FROM bl_3nf.ce_products_scd
        ORDER BY product_src_id, insert_dt DESC, product_id DESC
    ) s
    WHERE d.product_src_id = s.product_src_id
      AND d.is_active='Y'
      AND
      (
            d.product_name IS DISTINCT FROM s.product_name
		   OR d.brand IS DISTINCT FROM s.brand
		   OR d.category IS DISTINCT FROM s.category
		   OR d.subcategory IS DISTINCT FROM s.subcategory
		   OR d.color IS DISTINCT FROM s.color
		   OR d.size IS DISTINCT FROM s.size
		   OR d.unit_price IS DISTINCT FROM s.unit_price
		   OR d.unit_cost IS DISTINCT FROM s.unit_cost
		);

    ------------------------------------------------------------------
    -- Insert new products and new versions
    ------------------------------------------------------------------

    INSERT INTO bl_dm.dim_products_scd
    (
        product_surr_id,
        product_src_id,
        product_code,
        product_name,
        brand,
        category_src_id,
        category,
        subcategory_src_id,
        subcategory,
        color_src_id,
        color,
        size,
        unit_price,
        unit_cost,
        source_system,
        source_entity,
        start_dt,
        end_dt,
        is_active,
        insert_dt
    )

    SELECT
        nextval('bl_dm.seq_dim_product_surr_id'),

        s.product_src_id,
        s.product_code,
        s.product_name,
        s.brand,

        0,
        s.category,

        0,
        s.subcategory,

        0,
        s.color,

        s.size,
        s.unit_price,
        s.unit_cost,

        s.source_system,
        s.source_entity,

        CURRENT_DATE,
        DATE '9999-12-31',
        'Y',
        CURRENT_DATE

    FROM
    (
        SELECT DISTINCT ON (product_src_id)
               *
        FROM bl_3nf.ce_products_scd
        ORDER BY product_src_id, insert_dt DESC, product_id DESC
    ) s

    LEFT JOIN bl_dm.dim_products_scd d
           ON d.product_src_id=s.product_src_id
          AND d.is_active='Y'

    WHERE d.product_src_id IS NULL

       OR
		(
			  d.product_name IS DISTINCT FROM s.product_name
		   OR d.brand IS DISTINCT FROM s.brand
		   OR d.category IS DISTINCT FROM s.category
		   OR d.subcategory IS DISTINCT FROM s.subcategory
		   OR d.color IS DISTINCT FROM s.color
		   OR d.size IS DISTINCT FROM s.size
		   OR d.unit_price IS DISTINCT FROM s.unit_price
		   OR d.unit_cost IS DISTINCT FROM s.unit_cost
		);

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    CALL bl_cl.log_etl(
        'load_dim_products_scd',
        v_rows_affected,
        'DIM_PRODUCTS_SCD loaded successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
            'load_dim_products_scd',
            0,
            SQLERRM
        );

        RAISE;
END;
$$;


CALL bl_cl.load_dim_products_scd();

SELECT COUNT(*)
FROM bl_dm.dim_products_scd;

SELECT
    product_surr_id,
    product_src_id,
    product_name,
    start_dt,
    end_dt,
    is_active
FROM bl_dm.dim_products_scd
ORDER BY product_src_id
LIMIT 15

SELECT *
FROM bl_cl.etl_log
WHERE procedure_name = 'load_dim_products_scd'
ORDER BY log_id DESC;

-- Fact table

SELECT *
FROM bl_3nf.ce_sales
LIMIT 5;


CREATE TYPE bl_cl.sale_fact_rec AS
(
    customer_id      INTEGER,
    product_id       INTEGER,
    store_id         INTEGER,
    employee_id      INTEGER,
    date_id          INTEGER,
    quantity         INTEGER,
    unit_price       NUMERIC,
    unit_cost        NUMERIC,
    sales_amount     NUMERIC,
    cost_amount      NUMERIC,
    discount_amount  NUMERIC,
    payment_method   VARCHAR,
    channel          VARCHAR,
    insert_dt        TIMESTAMP,
    update_dt        TIMESTAMP
);

CREATE OR REPLACE PROCEDURE bl_cl.load_fct_sales_dd()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER := 0;
	v_inserted INTEGER;


BEGIN
	CALL bl_cl.manage_fct_sales_partitions();

		INSERT INTO bl_dm.fct_sales_dd
	(
		    customer_surr_id,
		    product_surr_id,
		    store_surr_id,
		    employee_surr_id,
		    date_surr_id,
		    event_dt,
		    quantity,
		    unit_price,
		    unit_cost,
		    sales_amount,
		    cost_amount,
		    discount_amount,
		    payment_method,
		    channel,
		    profit_amount,
		    insert_dt,
		    update_dt
	)
		SELECT
		    COALESCE(dc.customer_surr_id, -1),
		    dp.product_surr_id,
		    ds.store_surr_id,
		    COALESCE(de.employee_surr_id, -1),
		    dt.date_surr_id,
		    d.full_date,
		    s.quantity,
		    s.unit_price,
		    s.unit_cost,
		    s.sales_amount,
		    s.cost_amount,
		    s.discount_amount,
		    s.payment_method,
		    s.channel,
		    (s.sales_amount - s.cost_amount),
		    COALESCE(s.insert_dt::date, CURRENT_DATE),
		    COALESCE(s.update_dt::date, CURRENT_DATE)
		FROM bl_3nf.ce_sales s

		JOIN bl_3nf.ce_customers c
		    ON c.customer_id = s.customer_id
		
		LEFT JOIN bl_dm.dim_customer dc
		    ON dc.customer_src_id = c.customer_src_id
		
		JOIN bl_3nf.ce_products_scd p
		    ON p.product_id = s.product_id
		
		LEFT JOIN bl_dm.dim_products_scd dp
		    ON dp.product_src_id = p.product_src_id
		   AND dp.is_active = 'Y'
		
		JOIN bl_3nf.ce_stores st
		    ON st.store_id = s.store_id
		
		LEFT JOIN bl_dm.dim_store ds
		    ON ds.store_src_id = st.store_src_id
		
		LEFT JOIN bl_3nf.ce_employees e
		    ON e.employee_id = s.employee_id
		
		LEFT JOIN bl_dm.dim_employee de
		    ON de.employee_src_id = e.employee_src_id
		
		JOIN bl_3nf.ce_dates d
		    ON d.date_id = s.date_id
		
		LEFT JOIN bl_dm.dim_time_day dt
		    ON dt.event_dt = d.full_date
		
		WHERE NOT EXISTS
		(
		    SELECT 1
		    FROM bl_dm.fct_sales_dd f
		    WHERE f.customer_surr_id = COALESCE(dc.customer_surr_id, -1)
		      AND f.product_surr_id = dp.product_surr_id
		      AND f.store_surr_id = ds.store_surr_id
		      AND f.employee_surr_id = COALESCE(de.employee_surr_id, -1)
		      AND f.date_surr_id = dt.date_surr_id
		);

		GET DIAGNOSTICS v_inserted = ROW_COUNT;
		v_rows_affected := v_inserted;
    
	CALL bl_cl.log_etl
    (
        'load_fct_sales_dd',
        v_rows_affected,
        'FCT_SALES_DD loaded successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl
        (
            'load_fct_sales_dd',
            0,
            SQLERRM
        );

        RAISE;

END;
$$;

CALL bl_cl.load_fct_sales_dd();

SELECT COUNT(*)
FROM bl_dm.fct_sales_dd;

SELECT
    MIN(event_dt) AS min_date,
    MAX(event_dt) AS max_date,
    COUNT(*) AS rows_loaded
FROM bl_dm.fct_sales_dd;

SELECT
    tableoid::regclass AS partition_name,
    COUNT(*) AS rows
FROM bl_dm.fct_sales_dd
GROUP BY tableoid
ORDER BY partition_name;

SELECT *
FROM bl_cl.etl_log
WHERE procedure_name = 'load_fct_sales_dd'
ORDER BY log_id DESC;

SELECT COUNT(*)
FROM bl_3nf.ce_sales;

-- Procedure: bl_cl.validate_dm_load()

CREATE OR REPLACE PROCEDURE bl_cl.validate_dm_load
(
    INOUT p_result REFCURSOR
)
LANGUAGE plpgsql
AS
$$
BEGIN

    OPEN p_result FOR

    EXECUTE
    '
    SELECT ''DIM_CUSTOMER''      AS table_name, COUNT(*) AS row_count FROM bl_dm.dim_customer
    UNION ALL
    SELECT ''DIM_EMPLOYEE'',     COUNT(*) FROM bl_dm.dim_employee
    UNION ALL
    SELECT ''DIM_STORE'',        COUNT(*) FROM bl_dm.dim_store
    UNION ALL
    SELECT ''DIM_TIME_DAY'',     COUNT(*) FROM bl_dm.dim_time_day
    UNION ALL
    SELECT ''DIM_PRODUCTS_SCD'', COUNT(*) FROM bl_dm.dim_products_scd
    UNION ALL
    SELECT ''FCT_SALES_DD'',     COUNT(*) FROM bl_dm.fct_sales_dd
    ORDER BY table_name
    ';

END;
$$;

BEGIN;

CALL bl_cl.validate_dm_load('result');

FETCH ALL FROM result;

COMMIT;


SELECT
    product_src_id,
    product_name,
    unit_price,
    unit_cost,
    color,
    category
FROM bl_3nf.ce_products_scd
LIMIT 10;

SELECT *
FROM bl_3nf.ce_products_scd
WHERE product_src_id = 'P00001';

SELECT
    product_src_id,
    product_name,
    unit_price,
    start_dt,
    end_dt,
    is_active
FROM bl_dm.dim_products_scd
WHERE product_src_id = 'P00001';

SELECT *
FROM bl_3nf.ce_products_scd
WHERE product_src_id IN
(
    'P00169',
    'P00479',
    'P00426',
    'P00038',
    'P00142'
)
AND source_system = 'ONLINE'
ORDER BY product_src_id;

SELECT
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
    start_dt,
    end_dt,
    is_active
FROM bl_dm.dim_products_scd
WHERE product_src_id IN
(
    'P00169',
    'P00479',
    'P00426',
    'P00038',
    'P00142'
)
ORDER BY product_src_id, start_dt;


CREATE TABLE sa_online_sales.src_online_sales_backup AS
SELECT *
FROM sa_online_sales.src_online_sales;

TRUNCATE TABLE sa_online_sales.src_online_sales;

SELECT
    productid,
    unitprice
FROM sa_online_sales.src_online_sales
WHERE productid = 'P00169';

CALL bl_cl.load_ce_products_scd();

SELECT
    product_src_id,
    unit_price,
    source_system,
    insert_dt
FROM bl_3nf.ce_products_scd
WHERE product_src_id = 'P00169'
ORDER BY source_system;

CALL bl_cl.load_dim_products_scd();

SELECT
    product_src_id,
    unit_price,
    start_dt,
    end_dt,
    is_active
FROM bl_dm.dim_products_scd
WHERE product_src_id = 'P00169'
ORDER BY start_dt;

CALL bl_cl.load_dim_employee();

SELECT *
FROM bl_cl.etl_log
WHERE procedure_name = 'load_dim_employee'
ORDER BY log_id DESC
LIMIT 2;



-- Task 9
ALTER TABLE bl_dm.fct_sales_dd
RENAME TO fct_sales_dd_old;

SELECT COUNT(*)
FROM bl_dm.fct_sales_dd_old;

CREATE TABLE bl_dm.fct_sales_dd
(
    customer_surr_id     BIGINT NOT NULL,
    product_surr_id      BIGINT NOT NULL,
    store_surr_id        BIGINT NOT NULL,
    employee_surr_id     BIGINT NOT NULL,
    date_surr_id         BIGINT NOT NULL,

    event_dt             DATE NOT NULL,

    quantity             INTEGER,
    unit_price           NUMERIC,
    unit_cost            NUMERIC,
    sales_amount         NUMERIC,
    cost_amount          NUMERIC,
    discount_amount      NUMERIC,
    payment_method       VARCHAR(50),
    channel              VARCHAR(20),
    profit_amount        NUMERIC,

    insert_dt            DATE,
    update_dt            DATE,

    CONSTRAINT fk_fct_customer
        FOREIGN KEY (customer_surr_id)
        REFERENCES bl_dm.dim_customer(customer_surr_id),

    CONSTRAINT fk_fct_product
        FOREIGN KEY (product_surr_id)
        REFERENCES bl_dm.dim_products_scd(product_surr_id),

    CONSTRAINT fk_fct_store
        FOREIGN KEY (store_surr_id)
        REFERENCES bl_dm.dim_store(store_surr_id),

    CONSTRAINT fk_fct_employee
        FOREIGN KEY (employee_surr_id)
        REFERENCES bl_dm.dim_employee(employee_surr_id),

    CONSTRAINT fk_fct_date
        FOREIGN KEY (date_surr_id)
        REFERENCES bl_dm.dim_time_day(date_surr_id)

)
PARTITION BY RANGE (event_dt);

CREATE TABLE bl_dm.fct_sales_dd_default
PARTITION OF bl_dm.fct_sales_dd
DEFAULT;

CREATE TABLE bl_dm.fct_sales_2025_10
PARTITION OF bl_dm.fct_sales_dd
FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE bl_dm.fct_sales_2025_11
PARTITION OF bl_dm.fct_sales_dd
FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE bl_dm.fct_sales_2025_12
PARTITION OF bl_dm.fct_sales_dd
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_sales()
LANGUAGE plpgsql
AS
$$
DECLARE
    v_rows_affected INTEGER := 0;
    v_inserted INTEGER;
BEGIN
	RAISE NOTICE 'Loading CE_SALES...';
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
    s.paymentmethod,
    s.saleschannel,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM sa_online_sales.src_online_sales s

JOIN bl_3nf.ce_customers c
    ON c.customer_src_id = s.customerid
   AND c.source_system = 'ONLINE'

JOIN bl_3nf.ce_products_scd p
    ON p.product_src_id = s.productid
   AND p.source_system = 'ONLINE'
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
    s.paymentmethod,
    s.saleschannel,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM sa_store_sales.src_store_sales s

JOIN bl_3nf.ce_customers c
    ON c.customer_src_id = s.customerid
   AND c.source_system = 'STORE'

JOIN bl_3nf.ce_products_scd p
    ON p.product_src_id = s.productid
   AND p.source_system = 'STORE'
   AND p.is_active = TRUE

JOIN bl_3nf.ce_stores st
    ON st.store_src_id = s.storeid

LEFT JOIN bl_3nf.ce_employees e
    ON e.employee_src_id = s.employeeid

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
);

GET DIAGNOSTICS v_inserted = ROW_COUNT;
v_rows_affected := v_rows_affected + v_inserted;


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

-- GRANT PRIVILEGES TO BL_CL


GRANT USAGE
ON SCHEMA bl_dm
TO bl_cl;

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA bl_dm
TO bl_cl;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA bl_dm
TO bl_cl;

GRANT EXECUTE
ON ALL PROCEDURES IN SCHEMA bl_cl
TO bl_cl;

GRANT EXECUTE
ON ALL FUNCTIONS IN SCHEMA bl_cl
TO bl_cl;

GRANT USAGE
ON TYPE bl_cl.sale_fact_rec
TO bl_cl;

---------

CALL bl_cl.load_ce_sales();

SELECT COUNT(*)
FROM bl_3nf.ce_sales;

SELECT *
FROM bl_cl.etl_log
WHERE procedure_name = 'load_ce_sales'
ORDER BY log_id DESC
LIMIT 1;

SELECT *
FROM bl_cl.etl_log
WHERE procedure_name = 'load_ce_sales'
ORDER BY log_id DESC
LIMIT 2;

SELECT COUNT(*)
FROM bl_dm.fct_sales_dd_old;


CREATE OR REPLACE PROCEDURE bl_cl.manage_fct_sales_partitions()
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NOT EXISTS
    (
        SELECT 1
        FROM pg_class c
        JOIN pg_namespace n
          ON n.oid = c.relnamespace
        WHERE c.relname = 'fct_sales_2025_10'
          AND n.nspname = 'bl_dm'
    )
    THEN

        EXECUTE
        '
        CREATE TABLE bl_dm.fct_sales_2025_10
        PARTITION OF bl_dm.fct_sales_dd
        FOR VALUES FROM (''2025-10-01'') TO (''2025-11-01'')
        ';

    END IF;

END;
$$;

CALL bl_cl.manage_fct_sales_partitions();


SELECT
    customer_surr_id,
    product_surr_id,
    store_surr_id,
    employee_surr_id,
    date_surr_id,
    COUNT(*)
FROM bl_dm.fct_sales_dd
GROUP BY
    customer_surr_id,
    product_surr_id,
    store_surr_id,
    employee_surr_id,
    date_surr_id
HAVING COUNT(*) > 1;

SELECT
    source_system,
    sales_src_id,
    COUNT(*)
FROM bl_3nf.ce_sales
GROUP BY
    source_system,
    sales_src_id
HAVING COUNT(*) > 1;

SELECT *
FROM bl_cl.etl_log
ORDER BY log_id DESC;

SELECT
MIN(event_dt),
MAX(event_dt)
FROM bl_dm.fct_sales_dd;

SELECT
    MIN(full_date),
    MAX(full_date),
    COUNT(*)
FROM bl_3nf.ce_sales s
JOIN bl_3nf.ce_dates d
    ON d.date_id = s.date_id
WHERE d.full_date >=
(
    date_trunc
    (
        'month',
        (
            SELECT MAX(full_date)
            FROM bl_3nf.ce_dates
        )
    ) - interval '2 months'
);

CALL bl_cl.load_fct_sales_dd();

SELECT COUNT(*)
FROM bl_dm.fct_sales_dd;

SELECT
    MIN(full_date),
    MAX(full_date),
    COUNT(*)
FROM bl_3nf.ce_sales s
JOIN bl_3nf.ce_dates d
    ON d.date_id = s.date_id
WHERE d.full_date >=
(
    date_trunc(
        'month',
        (
            SELECT MAX(full_date)
            FROM bl_3nf.ce_dates
        )
    ) - interval '2 months'
);

CALL bl_cl.manage_fct_sales_partitions();

SELECT
    COUNT(*)
FROM bl_3nf.ce_sales s
JOIN bl_3nf.ce_customers c
    ON c.customer_id = s.customer_id
JOIN bl_dm.dim_customer dc
    ON dc.customer_src_id = c.customer_src_id;

