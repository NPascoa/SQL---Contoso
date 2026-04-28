--DATA VALIDATION AND QUALITY

--0 - check date columns for now:

select table_name,column_name, data_type
from information_schema.columns
where table_schema='public'
order by table_name, ordinal_position;

--All date columns are in fact of the date type.

*******************

--1 - Lets count the rows per table:
SELECT 
    'sales' AS table_name, 
    COUNT(*) AS row_count 
FROM sales
UNION ALL
SELECT 
    'customer', 
    COUNT(*) 
FROM customer
UNION ALL
SELECT 
    'product', 
    COUNT(*) 
FROM product
UNION ALL
SELECT 
    'store', 
    COUNT(*) 
FROM store
UNION ALL
SELECT 
    'date', 
    COUNT(*) 
FROM date
UNION ALL
SELECT 
    'currencyexchange', 
    COUNT(*) 
FROM currencyexchange;

/* RESULT:
"table_name","row_count"
"store","74"
"product","2517"
"date","3653"
"currencyexchange","91325"
"customer","104990"
"sales","199873"
*/


*******************

-- 2- check the Sales table which is the main:
-- info like rows, unique orders/customers/products/stores

SELECT
    COUNT(*) AS sales_rows, 
    COUNT(DISTINCT orderkey) AS unique_orders,
    COUNT(DISTINCT customerkey) AS unique_customers,
    COUNT(DISTINCT productkey) AS unique_products,
    COUNT(DISTINCT storekey) AS unique_stores
FROM sales;

/* RESULTS:
"sales_rows","unique_orders","unique_customers","unique_products","unique_stores"
"199873","83130","49487","2517","72"
*/



-- 3- check wether orders have appear more than once
-- in other words, if they have multple lines which we found out in query 2


SELECT
    SUM(line_count) as total_order_lines,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN line_count > 1 THEN 1 ELSE 0 END) AS multi_line_orders,
    ROUND(AVG(line_count),2) AS avg_lines_per_order,
    MIN(line_count) AS min_lines,
    MAX(line_count) AS max_lines,
    ROUND(SUM(CASE WHEN line_count > 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*),2) AS pct_multi_line
FROM (
    SELECT 
        orderkey, 
        COUNT(*) AS line_count
    FROM sales
    GROUP BY orderkey
) t;


/*RESULT:
"total_order_lines","total_orders","multi_line_orders","avg_lines_per_order","min_lines","max_lines","pct_multi_line"
"199873","83130","54171","2.40","1","7","0.65"
*/



-- 4 - check for nulls in the sales table:
-- Nulls ruin joins because they are removed from them.

SELECT
    COUNT(*) - COUNT(orderkey) as null_orderkey,
    -- or SUM(CASE WHEN orderkey IS NULL THEN 1 ELSE 0 END) AS null_orderkey - efficiency?
    COUNT(*) - COUNT(linenumber) AS null_linenumber,
    COUNT(*) - COUNT(deliverydate) AS null_deliverydate,
    COUNT(*) - COUNT(customerkey) AS null_customerkey,
    COUNT(*) - COUNT(storekey) AS null_storekey,
    COUNT(*) - COUNT(productkey) AS null_productkey,
    COUNT(*) - COUNT(quantity) AS null_quantity,
    COUNT(*) - COUNT(unitprice) AS null_unitprice,
    COUNT(*) - COUNT(netprice) AS null_netprice,
    COUNT(*) - COUNT(unitcost) AS null_unitcost,
    COUNT(*) - COUNT(exchangerate) AS null_exchangerate
FROM sales;


/*RESULT:
"null_orderkey","null_linenumber","null_orderdate","null_deliverydate","null_customerkey","null_storekey","null_productkey","null_quantity","null_unitprice","null_netprice","null_unitcost","null_exchangerate"
"0","0","0","0","0","0","0","0","0","0","0","0"
*/


-- 5- Check unusual values
-- besides missing data (nulls from query 4) some values make no sense 
-- therefore we need to check if they exist.
SELECT
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS nonpositive_quantity,
    SUM(CASE WHEN unitprice <= 0 THEN 1 ELSE 0 END) AS nonpositive_unitprice,
    SUM(CASE WHEN netprice <= 0 THEN 1 ELSE 0 END) AS nonpositive_netprice,
    SUM(CASE WHEN unitcost < 0 THEN 1 ELSE 0 END) AS negative_unitcost,
    SUM(CASE WHEN exchangerate <= 0 THEN 1 ELSE 0 END) AS nonpositive_exchangerate
FROM sales;

/*Result:
"nonpositive_quantity","negative_unitprice","negative_netprice","negative_unitcost","nonpositive_exchangerate"
"0","0","0","0","0"
*/


-- 6 -Revenue, cost, profit
SELECT
    ROUND(CAST(SUM(quantity * netprice / exchangerate) AS numeric), 2) AS total_revenue,
    ROUND(CAST(SUM(quantity * unitcost / exchangerate) AS numeric), 2) AS total_cost,
    ROUND(CAST(SUM((quantity * netprice / exchangerate) - (quantity * unitcost / exchangerate)) AS numeric), 2) AS total_profit
FROM sales;

/*REsult:
"total_revenue","total_cost","total_profit"
"206273146.45","90893542.43","115379604.03"
*/



-- 7- Date ranges
SELECT
    MIN(orderdate) AS min_orderdate,
    MAX(orderdate) AS max_orderdate,
    MIN(deliverydate) AS min_deliverydate,
    MAX(deliverydate) AS max_deliverydate
FROM sales;

/*Result:
"min_orderdate","max_orderdate","min_deliverydate","max_deliverydate"
"2015-01-01","2024-04-20","2015-01-01","2024-04-27"
*/

/*note that the max orderdate was 2024-04-20, so we will consider that our latest date of the dataset*/


-- 8- Delivery lag check
SELECT
    MIN(deliverydate - orderdate) AS min_delivery_days,
    MAX(deliverydate - orderdate) AS max_delivery_days,
    AVG(deliverydate - orderdate) AS avg_delivery_days,
    SUM(CASE WHEN deliverydate < orderdate THEN 1 ELSE 0 END) AS impossible_delivery
FROM sales
WHERE orderdate IS NOT NULL
AND deliverydate IS NOT NULL;

/*Result:
"min_delivery_days","max_delivery_days","avg_delivery_days","impossible_delivery"
0,19,"1.3067798051762869","0"
*/

-- 9 - Check whether unitprice and netprice differ
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN unitprice = netprice THEN 1 ELSE 0 END) AS same_price_rows,
    SUM(CASE WHEN unitprice <> netprice THEN 1 ELSE 0 END) AS different_price_rows
FROM sales;

/*Result:
"total_rows","same_price_rows","different_price_rows"
"199873","77533","122340"
*/

-- 10 - check duplicate keys in the customer and product tables:
SELECT 
    'customer' AS table_name, 
    customerkey AS key, 
    COUNT(*) AS instances
FROM customer
GROUP BY customerkey
HAVING COUNT(*) > 1

UNION ALL

SELECT 
    'product' AS table_name, 
    productkey AS key, 
    COUNT(*) AS instances
FROM product
GROUP BY productkey
HAVING COUNT(*) > 1;

-- No results


-- 11 - check if there are customers in sales that dont exist in customer

SELECT 
    COUNT(DISTINCT s.customerkey)
FROM sales s
LEFT JOIN customer c ON s.customerkey = c.customerkey
WHERE c.customerkey IS NULL;

-- No results



-- 12 - check duplicate order lines in sales table:
--each pair should uniquely identify a line.
SELECT
    orderkey,
    linenumber,
    COUNT(*) AS instances
FROM sales
GROUP BY orderkey, linenumber
HAVING COUNT(*) > 1;

-- No results.







































