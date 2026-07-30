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
        WHERE c.customer_src_id <> -1
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

            g.geo_id AS city_src_id,
            g.city,

            g.geo_id AS country_src_id,
            g.country,

            e.source_system,
            e.source_entity,

            COALESCE(e.insert_dt::date, CURRENT_DATE) AS insert_dt,
            COALESCE(e.update_dt::date, CURRENT_DATE) AS update_dt

        FROM bl_3nf.ce_employees e

        INNER JOIN bl_3nf.ce_stores s
            ON e.store_id = s.store_id

        INNER JOIN bl_3nf.ce_geographies g
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
BEGIN

    MERGE INTO bl_dm.dim_store AS tgt
    USING
    (
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

        WHERE s.store_src_id <> '-1'

    ) src

    ON tgt.store_src_id = src.store_src_id

    WHEN MATCHED THEN
        UPDATE
        SET
            store_name      = src.store_name,
            address         = src.address,
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
            src.store_src_id,
            src.store_name,
            src.address,
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
        'load_dim_store',
        v_rows_affected,
        'DIM_STORE loaded successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
            'load_dim_store',
            0,
            SQLERRM
        );

        RAISE;

END;
$$;


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
            d.product_name <> s.product_name
         OR d.brand <> s.brand
         OR d.category <> s.category
         OR d.subcategory <> s.subcategory
         OR d.color <> s.color
         OR d.size <> s.size
         OR d.unit_price <> s.unit_price
         OR d.unit_cost <> s.unit_cost
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
            d.product_name <> s.product_name
         OR d.brand <> s.brand
         OR d.category <> s.category
         OR d.subcategory <> s.subcategory
         OR d.color <> s.color
         OR d.size <> s.size
         OR d.unit_price <> s.unit_price
         OR d.unit_cost <> s.unit_cost
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


-- Fact table


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
		    dc.customer_surr_id,
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
		
		JOIN bl_dm.dim_customer dc
		    ON dc.customer_src_id = c.customer_src_id
		
		JOIN bl_3nf.ce_products_scd p
		    ON p.product_id = s.product_id
		
		JOIN bl_dm.dim_products_scd dp
		    ON dp.product_src_id = p.product_src_id
		   AND dp.is_active = 'Y'
		
		JOIN bl_3nf.ce_stores st
		    ON st.store_id = s.store_id
		
		JOIN bl_dm.dim_store ds
		    ON ds.store_src_id = st.store_src_id
		
		LEFT JOIN bl_3nf.ce_employees e
		    ON e.employee_id = s.employee_id
		
		LEFT JOIN bl_dm.dim_employee de
		    ON de.employee_src_id = e.employee_src_id
		
		JOIN bl_3nf.ce_dates d
		    ON d.date_id = s.date_id
		
		JOIN bl_dm.dim_time_day dt
		    ON dt.event_dt = d.full_date
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
		)
		AND NOT EXISTS
		(
		    SELECT 1
		    FROM bl_dm.fct_sales_dd f
		    WHERE f.customer_surr_id = dc.customer_surr_id
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


CREATE OR REPLACE PROCEDURE bl_cl.manage_fct_sales_partitions()
LANGUAGE plpgsql
AS
$$
BEGIN

    -- Detach oldest partition
    ALTER TABLE bl_dm.fct_sales_dd
    DETACH PARTITION bl_dm.fct_sales_2025_10;

    -- Attach it back
    ALTER TABLE bl_dm.fct_sales_dd
    ATTACH PARTITION bl_dm.fct_sales_2025_10
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

END;
$$;

