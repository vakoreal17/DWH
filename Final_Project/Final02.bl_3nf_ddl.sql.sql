CREATE SCHEMA IF NOT EXISTS bl_3nf;


CREATE TABLE IF NOT EXISTS bl_3nf.ce_dates
(
    date_id     SERIAL PRIMARY KEY,

    full_date   DATE NOT NULL,

    day         INTEGER NOT NULL,
    month       INTEGER NOT NULL,
    quarter     INTEGER NOT NULL,
    year        INTEGER NOT NULL,

    CONSTRAINT uq_ce_dates
        UNIQUE(full_date)
);


CREATE TABLE IF NOT EXISTS bl_3nf.ce_geographies
(
    geo_id          SERIAL PRIMARY KEY,

    country         VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,

    source_system   VARCHAR(30) NOT NULL,
    source_entity   VARCHAR(50) NOT NULL,
    geo_src_id      VARCHAR(100) NOT NULL,

    insert_dt       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_dt       TIMESTAMP,

    CONSTRAINT uq_ce_geographies
        UNIQUE (source_system, source_entity, geo_src_id)
);

CREATE TABLE IF NOT EXISTS bl_3nf.ce_customers
(
    customer_id         SERIAL PRIMARY KEY,

    customer_src_id     VARCHAR(100) NOT NULL,

    first_name          VARCHAR(100),
    last_name           VARCHAR(100),

    gender              VARCHAR(20),

    birth_date          DATE,

    email               VARCHAR(255),

    country             VARCHAR(100),

    city                VARCHAR(100),

    source_system       VARCHAR(30) NOT NULL,
    source_entity       VARCHAR(50) NOT NULL,

    insert_dt           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_dt           TIMESTAMP,

    CONSTRAINT uq_customer
        UNIQUE(source_system, source_entity, customer_src_id)
);


CREATE TABLE IF NOT EXISTS bl_3nf.ce_products_scd
(
    product_id          SERIAL,
    start_dt            DATE NOT NULL,

    product_src_id      VARCHAR(100) NOT NULL,

    product_code        VARCHAR(100),
    product_name        VARCHAR(255),

    brand               VARCHAR(100),
    category            VARCHAR(100),
    subcategory         VARCHAR(100),

    color               VARCHAR(50),
    size                VARCHAR(50),

    unit_price          NUMERIC(10,2),
    unit_cost           NUMERIC(10,2),

    source_system       VARCHAR(30) NOT NULL,
    source_entity       VARCHAR(50) NOT NULL,

    end_dt              DATE NOT NULL,
    is_active           BOOLEAN NOT NULL,

    insert_dt           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_products
        PRIMARY KEY(product_id,start_dt)
);

CREATE TABLE  IF NOT EXISTS bl_3nf.ce_stores
(
    store_id            SERIAL PRIMARY KEY,

    store_src_id        VARCHAR(100) NOT NULL,

    store_name          VARCHAR(255),

    address             VARCHAR(255),

    geo_id              INT NOT NULL,

    source_system       VARCHAR(30) NOT NULL,
    source_entity       VARCHAR(50) NOT NULL,

    insert_dt           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_dt           TIMESTAMP,

    CONSTRAINT fk_store_geo
        FOREIGN KEY(geo_id)
        REFERENCES bl_3nf.ce_geographies(geo_id),

    CONSTRAINT uq_store
        UNIQUE(source_system, source_entity, store_src_id)
);

CREATE TABLE IF NOT EXISTS bl_3nf.ce_employees
(
    employee_id         SERIAL PRIMARY KEY,

    employee_src_id     VARCHAR(100) NOT NULL,

    first_name          VARCHAR(100),

    last_name           VARCHAR(100),

    position            VARCHAR(100),

    store_id            INT,

    source_system       VARCHAR(30) NOT NULL,
    source_entity       VARCHAR(50) NOT NULL,

    insert_dt           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_dt           TIMESTAMP,

    CONSTRAINT fk_employee_store
        FOREIGN KEY(store_id)
        REFERENCES bl_3nf.ce_stores(store_id),

    CONSTRAINT uq_employee
        UNIQUE(source_system, source_entity, employee_src_id)
);

CREATE TABLE IF NOT EXISTS bl_3nf.ce_sales
(
    sales_id            BIGSERIAL PRIMARY KEY,

    customer_id         INT NOT NULL,

    product_id          INT NOT NULL,

    store_id            INT NOT NULL,

    employee_id         INT,

    date_id             INT NOT NULL,

    geo_id              INT NOT NULL,

    quantity            INT,

    unit_price          NUMERIC(10,2),

    unit_cost           NUMERIC(10,2),

    sales_amount        NUMERIC(12,2),

    cost_amount         NUMERIC(12,2),

    discount_amount     NUMERIC(12,2),
    
    sales_src_id 		VARCHAR(100) NOT NULL,
    
    source_system 		VARCHAR(30) NOT NULL,
    
    source_entity 		VARCHAR(50) NOT NULL,

    payment_method      VARCHAR(50),

    channel             VARCHAR(50),

    insert_dt           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    update_dt           TIMESTAMP,

    CONSTRAINT fk_sales_customer
        FOREIGN KEY(customer_id)
        REFERENCES bl_3nf.ce_customers(customer_id),

    CONSTRAINT fk_sales_store
        FOREIGN KEY(store_id)
        REFERENCES bl_3nf.ce_stores(store_id),

    CONSTRAINT fk_sales_employee
        FOREIGN KEY(employee_id)
        REFERENCES bl_3nf.ce_employees(employee_id),

    CONSTRAINT fk_sales_date
        FOREIGN KEY(date_id)
        REFERENCES bl_3nf.ce_dates(date_id),

    CONSTRAINT fk_sales_geo
        FOREIGN KEY(geo_id)
        REFERENCES bl_3nf.ce_geographies(geo_id),
        
    CONSTRAINT uq_sales
		UNIQUE(source_system, source_entity, sales_src_id)
);

INSERT INTO bl_3nf.ce_dates
(
    date_id,
    full_date,
    day,
    month,
    quarter,
    year
)
SELECT
    -1,
    DATE '1900-01-01',
    1,
    1,
    1,
    1900
WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_dates
    WHERE date_id = -1
);

INSERT INTO bl_3nf.ce_geographies
(
    geo_id,
    country,
    city,
    source_system,
    source_entity,
    geo_src_id
)
SELECT
    -1,
    'n.a.',
    'n.a.',
    'MANUAL',
    'DEFAULT',
    'n.a.'
WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_geographies
    WHERE geo_id = -1
);

INSERT INTO bl_3nf.ce_customers
(
    customer_id,
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
    -1,
    'n.a.',
    'n.a.',
    'n.a.',
    'n.a.',
    DATE '1900-01-01',
    'n.a.',
    'n.a.',
    'n.a.',
    'MANUAL',
    'DEFAULT'
WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_customers
    WHERE customer_id = -1
);

INSERT INTO bl_3nf.ce_products_scd
(
    product_id,
    start_dt,
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
    end_dt,
    is_active
)
SELECT
    -1,
    DATE '1900-01-01',
    'n.a.',
    'n.a.',
    'n.a.',
    'n.a.',
    'n.a.',
    'n.a.',
    'n.a.',
    'n.a.',
    0,
    0,
    'MANUAL',
    'DEFAULT',
    DATE '9999-12-31',
    TRUE
WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_products_scd
    WHERE product_id = -1
);

INSERT INTO bl_3nf.ce_stores
(
    store_id,
    store_src_id,
    store_name,
    address,
    geo_id,
    source_system,
    source_entity
)
SELECT
    -1,
    'n.a.',
    'n.a.',
    'n.a.',
    -1,
    'MANUAL',
    'DEFAULT'
WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_stores
    WHERE store_id = -1
);

INSERT INTO bl_3nf.ce_employees
(
    employee_id,
    employee_src_id,
    first_name,
    last_name,
    position,
    store_id,
    source_system,
    source_entity
)
SELECT
    -1,
    'n.a.',
    'n.a.',
    'n.a.',
    'n.a.',
    -1,
    'MANUAL',
    'DEFAULT'
WHERE NOT EXISTS
(
    SELECT 1
    FROM bl_3nf.ce_employees
    WHERE employee_id = -1
);

