--


-- CANNOT FORGET THAT RECENCY HAS A INVERTED SCALE

CREATE OR REPLACE VIEW rfm_scores as
WIth rfm_base as (
    Select
        customerkey,
        recency_days,
        order_count,
        lifetime_revenue
    from customer_summary
),

rfm_ranks as (
    select
        rb.*,

        percent_rank() over (order by recency_days ASC) as recency_pct,
        percent_rank() over (order by order_count DESC) as frequency_pct,
        percent_rank() over (order by lifetime_revenue DESC) as monetary_pct
    from rfm_base as rb
),

rfm_scored as (
    select
        customerkey,
        recency_days,
        order_count,
        lifetime_revenue,

        CASE
            when recency_pct < 0.20 then 5
            when recency_pct < 0.40 then 4
            when recency_pct < 0.60 then 3
            when recency_pct < 0.80 then 2
            else 1
        end as recency_score,

        CASE
            WHEN order_count = 1 THEN 1
            WHEN order_count = 2 THEN 2
            WHEN order_count = 3 THEN 3
            WHEN order_count = 4 THEN 4
            ELSE 5
        END AS frequency_score,


        CASE
            WHEN monetary_pct < 0.20 THEN 5
            WHEN monetary_pct < 0.40 THEN 4
            WHEN monetary_pct < 0.60 THEN 3
            WHEN monetary_pct < 0.80 THEN 2
            ELSE 1
        END AS monetary_score

    FROM rfm_ranks
)

select
    customerkey,
    recency_days,
    order_count,
    lifetime_revenue,
    recency_score,
    frequency_score,
    monetary_score,
    concat(recency_score,frequency_score,monetary_score) as rfm_score,
    (recency_score+frequency_score+monetary_score) as rfm_total_score
from rfm_scored
order by customerkey



---------

-- get the metric boundaries:

SELECT
    -- recency boundaries (ascending, so low value = score 5)
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY recency_days ASC) AS recency_p20,
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY recency_days ASC) AS recency_p40,
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY recency_days ASC) AS recency_p60,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY recency_days ASC) AS recency_p80,

    -- frequency boundaries (descending, so high value = score 5)
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY order_count DESC) AS frequency_p20,
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY order_count DESC) AS frequency_p40,
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY order_count DESC) AS frequency_p60,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY order_count DESC) AS frequency_p80,

    -- monetary boundaries (descending, so high value = score 5)
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY lifetime_revenue DESC) AS monetary_p20,
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY lifetime_revenue DESC) AS monetary_p40,
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY lifetime_revenue DESC) AS monetary_p60,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY lifetime_revenue DESC) AS monetary_p80

FROM customer_summary;

/* results:

"recency_p20","recency_p40","recency_p60","recency_p80","frequency_p20","frequency_p40","frequency_p60","frequency_p80","monetary_p20","monetary_p40","monetary_p60","monetary_p80"
268.2000000000007,542,858,1810,2,2,1,1,6652.996374928259,3415.654995870336,1701.258304,606.9617839999996

*/


-- number of customers by order count

SELECT
    order_count,
    COUNT(*) AS num_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_customers
FROM customer_summary
GROUP BY order_count
ORDER BY order_count;

/* Results:

"order_count","num_customers","pct_customers"
"1","27541","55.65"
"2","13914","28.12"
"3","5400","10.91"
"4","1873","3.78"
"5","559","1.13"
"6","145","0.29"
"7","39","0.08"
"8","14","0.03"
"9","1","0.00"
"10","1","0.00"

*/
