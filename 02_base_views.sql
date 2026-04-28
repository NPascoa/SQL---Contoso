-- Views to be used throughout the project:


-- 1 - order_base -> one row per order
-- we are collapsing the sales table from line by row to order by row.
-- we need to do this for the RFM and Cohort Analyses

CREATE OR REPLACE VIEW order_base AS
SELECT
    sales.orderkey,
    
    MIN(sales.orderdate) AS orderdate, 
    MAX(sales.deliverydate) AS deliverydate,
    MIN(sales.customerkey) AS customerkey,
    MIN(sales.storekey) AS storekey,

    COUNT(*) AS line_count, --per order
    COUNT(DISTINCT sales.productkey) AS distinct_products, --per order
    SUM(sales.quantity) AS total_units, -- per order

    SUM(sales.quantity * sales.netprice / sales.exchangerate) AS order_revenue,
    SUM(sales.quantity * sales.unitcost / sales.exchangerate) AS order_cost,
    SUM((sales.quantity * sales.netprice / sales.exchangerate) - (sales.quantity * sales.unitcost / sales.exchangerate)) AS order_profit,

    CASE
        WHEN SUM(sales.quantity * sales.netprice / sales.exchangerate) = 0 THEN NULL
        ELSE SUM((sales.quantity * sales.netprice / sales.exchangerate) - (sales.quantity * sales.unitcost / sales.exchangerate))
            / SUM(sales.quantity * sales.netprice / sales.exchangerate)
    END AS order_profit_margin,


    MAX(sales.deliverydate - sales.orderdate) AS delivery_days

FROM sales
GROUP BY sales.orderkey; 




-- 2 - order_extras -> with customer and store info


-- drop view if exists order_enriched - changed column name

CREATE OR REPLACE VIEW order_enriched AS
SELECT
    order_base.orderkey,
    order_base.orderdate,
    order_base.deliverydate,
    order_base.customerkey,
    order_base.storekey,
    order_base.line_count,
    order_base.distinct_products,
    order_base.total_units,
    order_base.order_revenue,
    order_base.order_cost,
    order_base.order_profit,
    order_base.order_profit_margin,
    order_base.delivery_days,

    customer.countryfull AS customer_country,
    customer.gender,
    customer.birthday,
    DATE_PART('year', AGE(order_base.orderdate, customer.birthday)) as age_at_order,
    customer.occupation, --possibly useful..
    CONCAT(TRIM(customer.givenname), ' ', TRIM(customer.surname)) AS customer_name,

    store.countryname AS store_country,
    store.state AS store_state,
    store.status AS store_status,
    store.squaremeters
FROM order_base
JOIN customer ON order_base.customerkey = customer.customerkey
JOIN store ON order_base.storekey = store.storekey;



