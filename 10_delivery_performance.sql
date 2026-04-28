--######## 1 - overall delivery stats ##########


SELECT
    round(avg(delivery_days),2) as avg_delivery_days,
    round((percentile_cont(0.5) within group (order by delivery_days ASC))::numeric,2) as median_delivery_days,
    round((percentile_cont(0.9) within group (order by delivery_days ASC))::numeric,2) as p90_delivery_days,
    max(delivery_days) as max_delivery_days
from order_enriched
where delivery_days is not null

/* results:

"avg_delivery_days","median_delivery_days","p90_delivery_days","max_delivery_days"
"1.30","0.00","4.00",19

*/



-- ########## 2 - Delivery performance by country ########

SELECT
    customer_country,
    COUNT(*) AS orders,
    ROUND(AVG(delivery_days),2) AS avg_delivery_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_days)::numeric,2) AS median_delivery_days,
    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY delivery_days)::numeric,2) AS p90_delivery_days
FROM order_enriched
GROUP BY customer_country
ORDER BY avg_delivery_days DESC;


/*

"customer_country","orders","avg_delivery_days","median_delivery_days","p90_delivery_days"
"France","2597","1.44","0.00","4.00"
"Australia","4937","1.35","0.00","4.00"
"Germany","8888","1.33","0.00","4.00"
"Netherlands","3483","1.32","0.00","4.00"
"United States","43531","1.31","0.00","4.00"
"Canada","8717","1.30","0.00","4.00"
"United Kingdom","8578","1.18","0.00","4.00"
"Italy","2399","1.15","0.00","4.00"

*/


-- ##### 3 - delivery distibution buckets #########

SELECT
    CASE
        WHEN delivery_days <= 3 THEN '0–3 days'
        WHEN delivery_days <= 7 THEN '4–7 days'
        WHEN delivery_days <= 14 THEN '8–14 days'
        WHEN delivery_days <= 30 THEN '15–30 days'
        ELSE '30+ days'
    END AS delivery_bucket,
    COUNT(*) AS orders
FROM order_enriched
GROUP BY delivery_bucket
ORDER BY MIN(delivery_days);

/* resukts:

"delivery_bucket","orders"
"0–3 days","70440"
"4–7 days","11887"
"8–14 days","782"
"15–30 days","21"





