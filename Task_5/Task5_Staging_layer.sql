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
    onlineorderid      VARCHAR(1000),
	orderdate          VARCHAR(1000),
	year               VARCHAR(1000),
	quarter            VARCHAR(1000),
	month              VARCHAR(1000),
	day                VARCHAR(1000),

	customerid         VARCHAR(1000),
	firstname          VARCHAR(1000),
	lastname           VARCHAR(1000),
	gender             VARCHAR(1000),
	birthdate          VARCHAR(1000),
	email              VARCHAR(1000),
	customercountry    VARCHAR(1000),
	customercity       VARCHAR(1000),

	productid          VARCHAR(1000),
	productcode        VARCHAR(1000),
	productname        VARCHAR(1000),
	brand              VARCHAR(1000),
	category           VARCHAR(1000),
	subcategory        VARCHAR(1000),
	color              VARCHAR(1000),
	size               VARCHAR(1000),

	quantity           VARCHAR(1000),
	unitprice          VARCHAR(1000),
	unitcost           VARCHAR(1000),
	salesamount        VARCHAR(1000),
	costamount         VARCHAR(1000),
	discountamount     VARCHAR(1000),

	paymentmethod      VARCHAR(1000),
	shippingtype       VARCHAR(1000),
	couponcode         VARCHAR(1000),
	saleschannel       VARCHAR(1000)
)
SERVER file_server
OPTIONS
(
    filename 'C:/Users/Vago/Desktop/Task_1/generated_data/nike_online_sales.csv',
    format 'csv',
    header 'true'
);

CREATE TABLE IF NOT EXISTS sa_online_sales.src_online_sales
(
    onlineorderid      VARCHAR(1000),
	orderdate          VARCHAR(1000),
	year               VARCHAR(1000),
	quarter            VARCHAR(1000),
	month              VARCHAR(1000),
	day                VARCHAR(1000),

	customerid         VARCHAR(1000),
	firstname          VARCHAR(1000),
	lastname           VARCHAR(1000),
	gender             VARCHAR(1000),
	birthdate          VARCHAR(1000),
	email              VARCHAR(1000),
	customercountry    VARCHAR(1000),
	customercity       VARCHAR(1000),

	productid          VARCHAR(1000),
	productcode        VARCHAR(1000),
	productname        VARCHAR(1000),
	brand              VARCHAR(1000),
	category           VARCHAR(1000),
	subcategory        VARCHAR(1000),
	color              VARCHAR(1000),
	size               VARCHAR(1000),

	quantity           VARCHAR(1000),
	unitprice          VARCHAR(1000),
	unitcost           VARCHAR(1000),
	salesamount        VARCHAR(1000),
	costamount         VARCHAR(1000),
	discountamount     VARCHAR(1000),

	paymentmethod      VARCHAR(1000),
	shippingtype       VARCHAR(1000),
	couponcode         VARCHAR(1000),
	saleschannel       VARCHAR(1000)
);

------------------------------------------------------------
-- Load Data into Source Table
------------------------------------------------------------
INSERT INTO sa_online_sales.src_online_sales
SELECT
    onlineorderid,
    orderdate,
    year,
    quarter,
    month,
    day,
    customerid,
    firstname,
    lastname,
    gender,
    birthdate,
    email,
    customercountry,
    customercity,
    productid,
    productcode,
    productname,
    brand,
    category,
    subcategory,
    color,
    size,
    quantity,
    unitprice,
    unitcost,
    salesamount,
    costamount,
    discountamount,
    paymentmethod,
    shippingtype,
    couponcode,
    saleschannel
FROM (
    SELECT
        onlineorderid,
        orderdate,
        year,
        quarter,
        month,
        day,
        customerid,
        firstname,
        lastname,
        gender,
        birthdate,
        email,
        customercountry,
        customercity,
        productid,
        productcode,
        productname,
        brand,
        category,
        subcategory,
        color,
        size,
        quantity,
        unitprice,
        unitcost,
        salesamount,
        costamount,
        discountamount,
        paymentmethod,
        shippingtype,
        couponcode,
        saleschannel,
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
    receiptid          VARCHAR(1000),
	saledate           VARCHAR(1000),
	year               VARCHAR(1000),
	quarter            VARCHAR(1000),
	month              VARCHAR(1000),
	day                VARCHAR(1000),

	customerid         VARCHAR(1000),
	firstname          VARCHAR(1000),
	lastname           VARCHAR(1000),
	gender             VARCHAR(1000),
	birthdate          VARCHAR(1000),
	email              VARCHAR(1000),
	customercountry    VARCHAR(1000),
	customercity       VARCHAR(1000),

	storeid            VARCHAR(1000),
	storename          VARCHAR(1000),
	storeaddress       VARCHAR(1000),
	storecountry       VARCHAR(1000),
	storecity          VARCHAR(1000),

	employeeid         VARCHAR(1000),
	employeename       VARCHAR(1000),
	position           VARCHAR(1000),

	productid          VARCHAR(1000),
	productcode        VARCHAR(1000),
	productname        VARCHAR(1000),
	brand              VARCHAR(1000),
	category           VARCHAR(1000),
	subcategory        VARCHAR(1000),
	color              VARCHAR(1000),
	size               VARCHAR(1000),

	quantity           VARCHAR(1000),
	unitprice          VARCHAR(1000),
	unitcost           VARCHAR(1000),
	salesamount        VARCHAR(1000),
	costamount         VARCHAR(1000),
	discountamount     VARCHAR(1000),

	registernumber     VARCHAR(1000),
	shift              VARCHAR(1000),
	paymentmethod      VARCHAR(1000),
	saleschannel       VARCHAR(1000)
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

CREATE TABLE IF NOT EXISTS sa_store_sales.src_store_sales
(
    receiptid          VARCHAR(1000),
	saledate           VARCHAR(1000),
	year               VARCHAR(1000),
	quarter            VARCHAR(1000),
	month              VARCHAR(1000),
	day                VARCHAR(1000),

	customerid         VARCHAR(1000),
	firstname          VARCHAR(1000),
	lastname           VARCHAR(1000),
	gender             VARCHAR(1000),
	birthdate          VARCHAR(1000),
	email              VARCHAR(1000),
	customercountry    VARCHAR(1000),
	customercity       VARCHAR(1000),

	storeid            VARCHAR(1000),
	storename          VARCHAR(1000),
	storeaddress       VARCHAR(1000),
	storecountry       VARCHAR(1000),
	storecity          VARCHAR(1000),

	employeeid         VARCHAR(1000),
	employeename       VARCHAR(1000),
	position           VARCHAR(1000),

	productid          VARCHAR(1000),
	productcode        VARCHAR(1000),
	productname        VARCHAR(1000),
	brand              VARCHAR(1000),
	category           VARCHAR(1000),
	subcategory        VARCHAR(1000),
	color              VARCHAR(1000),
	size               VARCHAR(1000),

	quantity           VARCHAR(1000),
	unitprice          VARCHAR(1000),
	unitcost           VARCHAR(1000),
	salesamount        VARCHAR(1000),
	costamount         VARCHAR(1000),
	discountamount     VARCHAR(1000),

	registernumber     VARCHAR(1000),
	shift              VARCHAR(1000),
	paymentmethod      VARCHAR(1000),
	saleschannel       VARCHAR(1000)
);

INSERT INTO sa_store_sales.src_store_sales
SELECT
    receiptid,
    saledate,
    year,
    quarter,
    month,
    day,
    customerid,
    firstname,
    lastname,
    gender,
    birthdate,
    email,
    customercountry,
    customercity,
    storeid,
    storename,
    storeaddress,
    storecountry,
    storecity,
    employeeid,
    employeename,
    position,
    productid,
    productcode,
    productname,
    brand,
    category,
    subcategory,
    color,
    size,
    quantity,
    unitprice,
    unitcost,
    salesamount,
    costamount,
    discountamount,
    registernumber,
    shift,
    paymentmethod,
    saleschannel
FROM (
    SELECT
        receiptid,
        saledate,
        year,
        quarter,
        month,
        day,
        customerid,
        firstname,
        lastname,
        gender,
        birthdate,
        email,
        customercountry,
        customercity,
        storeid,
        storename,
        storeaddress,
        storecountry,
        storecity,
        employeeid,
        employeename,
        position,
        productid,
        productcode,
        productname,
        brand,
        category,
        subcategory,
        color,
        size,
        quantity,
        unitprice,
        unitcost,
        salesamount,
        costamount,
        discountamount,
        registernumber,
        shift,
        paymentmethod,
        saleschannel,
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

SELECT
    onlineorderid,
    orderdate,
    year,
    quarter,
    month,
    day,
    customerid,
    firstname,
    lastname,
    gender,
    birthdate,
    email,
    customercountry,
    customercity,
    productid,
    productcode,
    productname,
    brand,
    category,
    subcategory,
    color,
    size,
    quantity,
    unitprice,
    unitcost,
    salesamount,
    costamount,
    discountamount,
    paymentmethod,
    shippingtype,
    couponcode,
    saleschannel
FROM sa_online_sales.ext_online_sales
LIMIT 10;

SELECT
    onlineorderid,
    orderdate,
    year,
    quarter,
    month,
    day,
    customerid,
    firstname,
    lastname,
    gender,
    birthdate,
    email,
    customercountry,
    customercity,
    productid,
    productcode,
    productname,
    brand,
    category,
    subcategory,
    color,
    size,
    quantity,
    unitprice,
    unitcost,
    salesamount,
    costamount,
    discountamount,
    paymentmethod,
    shippingtype,
    couponcode,
    saleschannel
FROM sa_online_sales.src_online_sales
LIMIT 10;



SELECT COUNT(*) external_rows
FROM sa_store_sales.ext_store_sales;

SELECT COUNT(*) source_rows
FROM sa_store_sales.src_store_sales;

SELECT
    receiptid,
    saledate,
    year,
    quarter,
    month,
    day,
    customerid,
    firstname,
    lastname,
    gender,
    birthdate,
    email,
    customercountry,
    customercity,
    storeid,
    storename,
    storeaddress,
    storecountry,
    storecity,
    employeeid,
    employeename,
    position,
    productid,
    productcode,
    productname,
    brand,
    category,
    subcategory,
    color,
    size,
    quantity,
    unitprice,
    unitcost,
    salesamount,
    costamount,
    discountamount,
    registernumber,
    shift,
    paymentmethod,
    saleschannel
FROM sa_store_sales.ext_store_sales
LIMIT 10;

SELECT
    receiptid,
    saledate,
    year,
    quarter,
    month,
    day,
    customerid,
    firstname,
    lastname,
    gender,
    birthdate,
    email,
    customercountry,
    customercity,
    storeid,
    storename,
    storeaddress,
    storecountry,
    storecity,
    employeeid,
    employeename,
    position,
    productid,
    productcode,
    productname,
    brand,
    category,
    subcategory,
    color,
    size,
    quantity,
    unitprice,
    unitcost,
    salesamount,
    costamount,
    discountamount,
    registernumber,
    shift,
    paymentmethod,
    saleschannel
FROM sa_store_sales.src_store_sales
LIMIT 10;

COMMIT;