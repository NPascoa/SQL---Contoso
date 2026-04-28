-- In this section, the goal is to find who are the most valuable customers in terms of profit.
-- Since I care about profitability, I will be using the metric: lifetime_profit (instead of lifetime_Revenue)


-- View of the segmentation:

CREATE OR REPLACE VIEW customer_value_segments as
With value_distribution as( 
    SELECT
        percentile_cont(0.25) within group (order by lifetime_profit) as p25,
        percentile_cont(0.50) within group (order by lifetime_profit) as p50,
        percentile_cont(0.75) within group (order by lifetime_profit) as p75
    From customer_summary
)

select
    cs.customerkey,
    cs.lifetime_revenue,
    cs.lifetime_profit,
    cs.order_count,

    case
        when cs.lifetime_profit >= vd.p75 then 'High Value'
        when cs.lifetime_profit >= vd.p50 then 'Mid-High Value'
        when cs.lifetime_profit >= vd.p25 then 'Low-Mid Value'
        Else 'Low Value'
    end as value_segment
from customer_summary cs
cross join value_distribution vd;


-- Summary info:

SELECT
    value_segment,
    count(*) as customers,
    Round(Avg(lifetime_profit)::numeric,2) as avg_customer_profit,
    Round(Sum(lifetime_profit)::numeric,2) as total_profit,
    Round(avg(order_count)::numeric,2) as avg_orders,
    Round((sum(lifetime_profit)/sum(sum(lifetime_profit)) over())::numeric,2) as profit_share  
From customer_value_segments
Group by value_segment
Order by total_profit Desc


/* results:

"value_segment","customers","avg_customer_profit","total_profit","avg_orders","profit_share"
"High Value","12372","6279.47","77689549.67","2.34","0.67"
"Mid-High Value","12372","2043.59","25283332.19","1.80","0.22"
"Low-Mid Value","12371","825.15","10207917.13","1.45","0.09"
"Low Value","12372","177.72","2198805.04","1.14","0.02"

*/
