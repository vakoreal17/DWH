------------------------------------------------------------
-- Enable file_fdw extension
------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS file_fdw;

------------------------------------------------------------
-- Create Foreign Server
------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_foreign_server
        WHERE srvname = 'file_server'
    ) THEN
        CREATE SERVER file_server
        FOREIGN DATA WRAPPER file_fdw;
    END IF;
END $$;
------------------------------------------------------------
-- Create Staging Schema
------------------------------------------------------------

CREATE SCHEMA if not exists sa_online_sales;

------------------------------------------------------------
-- Create External (Foreign) Table
------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.foreign_tables
        WHERE foreign_table_schema = 'sa_online_sales'
          AND foreign_table_name = 'ext_online_sales'
    ) THEN

        CREATE FOREIGN TABLE sa_online_sales.ext_online_sales
        (
            onlineorderid      TEXT,
            orderdate          DATE,
            year               INTEGER,
            quarter            INTEGER,
            month              INTEGER,
            day                INTEGER,

            customerid         TEXT,
            firstname          TEXT,
            lastname           TEXT,
            gender             TEXT,
            birthdate          DATE,
            email              TEXT,
            customercountry    TEXT,
            customercity       TEXT,

            productid          TEXT,
            productcode        TEXT,
            productname        TEXT,
            brand              TEXT,
            category           TEXT,
            subcategory        TEXT,
            color              TEXT,
            size               TEXT,

            quantity           INTEGER,
            unitprice          NUMERIC(10,2),
            unitcost           NUMERIC(10,2),
            salesamount        NUMERIC(12,2),
            costamount         NUMERIC(12,2),
            discountamount     NUMERIC(12,2),

            paymentmethod      TEXT,
            shippingtype       TEXT,
            couponcode         TEXT,
            saleschannel       TEXT
        )
        SERVER file_server
        OPTIONS
        (
            filename 'C:/Users/Vago/Desktop/Task_1/generated_data/nike_online_sales.csv',
            format 'csv',
            header 'true'
        );

    END IF;
END $$;


CREATE TABLE if not exists  sa_online_sales.src_online_sales
(
    onlineorderid      TEXT,
    orderdate          DATE,
    year               INTEGER,
    quarter            INTEGER,
    month              INTEGER,
    day                INTEGER,

    customerid         TEXT,
    firstname          TEXT,
    lastname           TEXT,
    gender             TEXT,
    birthdate          DATE,
    email              TEXT,
    customercountry    TEXT,
    customercity       TEXT,

    productid          TEXT,
    productcode        TEXT,
    productname        TEXT,
    brand              TEXT,
    category           TEXT,
    subcategory        TEXT,
    color              TEXT,
    size               TEXT,

    quantity           INTEGER,
    unitprice          NUMERIC(10,2),
    unitcost           NUMERIC(10,2),
    salesamount        NUMERIC(12,2),
    costamount         NUMERIC(12,2),
    discountamount     NUMERIC(12,2),

    paymentmethod      TEXT,
    shippingtype       TEXT,
    couponcode         TEXT,
    saleschannel       TEXT
);

------------------------------------------------------------
-- Load Data into Source Table
------------------------------------------------------------
INSERT INTO sa_online_sales.src_online_sales
SELECT DISTINCT e.*
FROM sa_online_sales.ext_online_sales e
WHERE e.onlineorderid IS NOT NULL
  AND NOT EXISTS
(
    SELECT 1
    FROM sa_online_sales.src_online_sales s
    WHERE s.onlineorderid = e.onlineorderid
);

------------------------------------------------------------
-- Verification Queries
------------------------------------------------------------
SELECT COUNT(*) AS external_rows
FROM sa_online_sales.ext_online_sales;

SELECT COUNT(*) AS source_rows
FROM sa_online_sales.src_online_sales;

SELECT *
FROM sa_online_sales.ext_online_sales
LIMIT 10;

SELECT *
FROM sa_online_sales.src_online_sales
LIMIT 10;

------------------------------------------------------------
-- Part 2 Store Sales.
------------------------------------------------------------

CREATE SCHEMA if not exists sa_store_sales;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.foreign_tables
        WHERE foreign_table_schema = 'sa_store_sales'
          AND foreign_table_name = 'ext_store_sales'
    ) THEN

        CREATE FOREIGN TABLE sa_store_sales.ext_store_sales
        (
            receiptid          TEXT,
            saledate           DATE,
            year               INTEGER,
            quarter            INTEGER,
            month              INTEGER,
            day                INTEGER,

            customerid         TEXT,
            firstname          TEXT,
            lastname           TEXT,
            gender             TEXT,
            birthdate          DATE,
            email              TEXT,
            customercountry    TEXT,
            customercity       TEXT,

            storeid            TEXT,
            storename          TEXT,
            storeaddress       TEXT,
            storecountry       TEXT,
            storecity          TEXT,

            employeeid         TEXT,
            employeename       TEXT,
            position           TEXT,

            productid          TEXT,
            productcode        TEXT,
            productname        TEXT,
            brand              TEXT,
            category           TEXT,
            subcategory        TEXT,
            color              TEXT,
            size               TEXT,

            quantity           INTEGER,
            unitprice          NUMERIC(10,2),
            unitcost           NUMERIC(10,2),
            salesamount        NUMERIC(12,2),
            costamount         NUMERIC(12,2),
            discountamount     NUMERIC(12,2),

            registernumber     INTEGER,
            shift              TEXT,
            paymentmethod      TEXT,
            saleschannel       TEXT
        )
        SERVER file_server
        OPTIONS
        (
            filename 'C:/Users/Vago/Desktop/Task_1/generated_data/nike_store_sales.csv',
            format 'csv',
            header 'true'
        );

    END IF;
END $$;

SELECT *
FROM sa_store_sales.ext_store_sales
LIMIT 10;


CREATE TABLE if not exists sa_store_sales.src_store_sales
(
    receiptid          TEXT,
    saledate           DATE,
    year               INTEGER,
    quarter            INTEGER,
    month              INTEGER,
    day                INTEGER,

    customerid         TEXT,
    firstname          TEXT,
    lastname           TEXT,
    gender             TEXT,
    birthdate          DATE,
    email              TEXT,
    customercountry    TEXT,
    customercity       TEXT,

    storeid            TEXT,
    storename          TEXT,
    storeaddress       TEXT,
    storecountry       TEXT,
    storecity          TEXT,

    employeeid         TEXT,
    employeename       TEXT,
    position           TEXT,

    productid          TEXT,
    productcode        TEXT,
    productname        TEXT,
    brand              TEXT,
    category           TEXT,
    subcategory        TEXT,
    color              TEXT,
    size               TEXT,

    quantity           INTEGER,
    unitprice          NUMERIC(10,2),
    unitcost           NUMERIC(10,2),
    salesamount        NUMERIC(12,2),
    costamount         NUMERIC(12,2),
    discountamount     NUMERIC(12,2),

    registernumber     INTEGER,
    shift              TEXT,
    paymentmethod      TEXT,
    saleschannel       TEXT
);

INSERT INTO sa_store_sales.src_store_sales
SELECT DISTINCT e.*
FROM sa_store_sales.ext_store_sales e
WHERE e.receiptid IS NOT NULL
  AND NOT EXISTS
(
    SELECT 1
    FROM sa_store_sales.src_store_sales s
    WHERE s.receiptid = e.receiptid
);

SELECT COUNT(*) external_rows
FROM sa_store_sales.ext_store_sales;

SELECT COUNT(*) source_rows
FROM sa_store_sales.src_store_sales;

SELECT *
FROM sa_store_sales.ext_store_sales
LIMIT 10;

SELECT *
FROM sa_store_sales.src_store_sales
LIMIT 10;