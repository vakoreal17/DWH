------------------------------------------------------------
-- Enable file_fdw extension
------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS file_fdw;

------------------------------------------------------------
-- Create Foreign Server
------------------------------------------------------------
CREATE SERVER IF NOT EXISTS file_server
FOREIGN DATA WRAPPER file_fdw;
------------------------------------------------------------
-- Create Staging Schema
------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS sa_online_sales;
------------------------------------------------------------
-- Create External (Foreign) Table
------------------------------------------------------------
CREATE FOREIGN TABLE sa_online_sales.ext_online_sales
(
    onlineorderid      VARCHAR(100),
    orderdate          VARCHAR(50),
    year               VARCHAR(10),
    quarter            VARCHAR(10),
    month              VARCHAR(10),
    day                VARCHAR(10),

    customerid         VARCHAR(100),
    firstname          VARCHAR(100),
    lastname           VARCHAR(100),
    gender             VARCHAR(20),
    birthdate          VARCHAR(50),
    email              VARCHAR(255),
    customercountry    VARCHAR(100),
    customercity       VARCHAR(100),

    productid          VARCHAR(100),
    productcode        VARCHAR(100),
    productname        VARCHAR(255),
    brand              VARCHAR(100),
    category           VARCHAR(100),
    subcategory        VARCHAR(100),
    color              VARCHAR(50),
    size               VARCHAR(50),

    quantity           VARCHAR(20),
    unitprice          VARCHAR(30),
    unitcost           VARCHAR(30),
    salesamount        VARCHAR(30),
    costamount         VARCHAR(30),
    discountamount     VARCHAR(30),

    paymentmethod      VARCHAR(50),
    shippingtype       VARCHAR(50),
    couponcode         VARCHAR(100),
    saleschannel       VARCHAR(50)
)
SERVER file_server
OPTIONS
(
    filename 'C:/Users/Vago/Desktop/Task_1/generated_data/nike_online_sales.csv',
    format 'csv',
    header 'true'
);

DROP TABLE IF EXISTS sa_online_sales.src_online_sales;

CREATE TABLE sa_online_sales.src_online_sales
(
    onlineorderid      VARCHAR(100),
    orderdate          VARCHAR(50),
    year               VARCHAR(10),
    quarter            VARCHAR(10),
    month              VARCHAR(10),
    day                VARCHAR(10),

    customerid         VARCHAR(100),
    firstname          VARCHAR(100),
    lastname           VARCHAR(100),
    gender             VARCHAR(20),
    birthdate          VARCHAR(50),
    email              VARCHAR(255),
    customercountry    VARCHAR(100),
    customercity       VARCHAR(100),

    productid          VARCHAR(100),
    productcode        VARCHAR(100),
    productname        VARCHAR(255),
    brand              VARCHAR(100),
    category           VARCHAR(100),
    subcategory        VARCHAR(100),
    color              VARCHAR(50),
    size               VARCHAR(50),

    quantity           VARCHAR(20),
    unitprice          VARCHAR(30),
    unitcost           VARCHAR(30),
    salesamount        VARCHAR(30),
    costamount         VARCHAR(30),
    discountamount     VARCHAR(30),

    paymentmethod      VARCHAR(50),
    shippingtype       VARCHAR(50),
    couponcode         VARCHAR(100),
    saleschannel       VARCHAR(50)
);

------------------------------------------------------------
-- Load Data into Source Table
------------------------------------------------------------
INSERT INTO sa_online_sales.src_online_sales
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY onlineorderid
               ORDER BY onlineorderid
           ) AS rn
    FROM sa_online_sales.ext_online_sales
) t
WHERE rn = 1;

------------------------------------------------------------
-- Part 2 Store Sales.
------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS sa_store_sales;

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

SELECT *
FROM sa_store_sales.ext_store_sales
LIMIT 10;

DROP TABLE IF EXISTS sa_store_sales.src_store_sales;

CREATE TABLE sa_store_sales.src_store_sales
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
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY receiptid
               ORDER BY receiptid
           ) AS rn
    FROM sa_store_sales.ext_store_sales
) t
WHERE rn = 1;

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

COMMIT;