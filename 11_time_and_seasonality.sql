-- In this section the goal is understand how order, revenue and profit evolve over time.
-- Do purhcases vary by day of the week?
-- Are there recurring seasonal peaks within a year?


-- ###### 1 - monthly trends (order, revenue and profit)

Select
    date_trunc('month',orderdate)::date as month,
    count(distinct orderkey) as orders,
    round(sum(order_revenue)::numeric,2) as revenue,
    round(sum(order_profit)::numeric,2) as profit
From
    order_enriched
Group by date_trunc('month',orderdate)
order by month

/* results:
"month","orders","revenue","profit"
"2015-01-01","200","492333.08","280261.46"
"2015-02-01","292","754890.51","430206.83"
"2015-03-01","139","380417.65","219461.42"
"2015-04-01","78","166474.20","93237.30"


*/


-- ##### 2 - Seasonality ####

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', orderdate)::date AS month,
        EXTRACT(YEAR FROM orderdate) AS year,
        EXTRACT(MONTH FROM orderdate) AS month_number,
        COUNT(DISTINCT orderkey) AS orders,
        SUM(order_revenue) AS revenue,
        SUM(order_profit) AS profit
    FROM order_enriched
    GROUP BY
        DATE_TRUNC('month', orderdate)::date,
        EXTRACT(YEAR FROM orderdate),
        EXTRACT(MONTH FROM orderdate)
)

SELECT
    month_number,
    ROUND(AVG(orders),2)  AS avg_monthly_orders,
    ROUND(AVG(revenue)::numeric,2) AS avg_monthly_revenue,
    ROUND(AVG(profit)::numeric,2)  AS avg_monthly_profit
FROM monthly
GROUP BY month_number
ORDER BY month_number;


/* results:

"month_number","avg_monthly_orders","avg_monthly_revenue","avg_monthly_profit"
"1","804.40","2006024.31","1124160.82"
"2","1051.00","2602647.24","1453795.98"
"3","561.00","1360899.26","761155.61"
"4","289.40","720685.59","404706.71"
"5","753.00","1919429.15","1075491.04"
"6","785.44","2099151.61","1169266.74"
"7","670.56","1619029.09","904511.46"
"8","720.00","1786603.33","1001196.21"
"9","764.11","1866206.06","1047550.93"
"10","787.22","1920342.95","1073165.82"
"11","779.33","1922233.53","1075118.30"
"12","970.56","2352624.54","1313856.45"

*/



-- ##### 3 - Orders by day of week #####

SELECT
    EXTRACT(DOW FROM orderdate) AS day_of_week,
    to_char(orderdate, 'Day') as day_name,
    COUNT(DISTINCT orderkey) AS orders
FROM order_enriched
GROUP BY EXTRACT(DOW FROM orderdate), day_name
ORDER BY day_of_week;


/* results:

"day_of_week","day_name","orders"
"0","Sunday   ","1691"
"1","Monday   ","8791"
"2","Tuesday  ","11215"
"3","Wednesday","14762"
"4","Thursday ","15958"
"5","Friday   ","11190"
"6","Saturday ","19523"

*/




