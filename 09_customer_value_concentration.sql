-- Goal is to identify how profit is distributed across customers
    --how much profit comes from top customers?
    --is profit highly concentrated?
    --which segments generate the most value?

-- ### 1 - Pareto or customer value tiers: #####

WITH customer_ranked AS (
    SELECT
        customerkey,
        lifetime_profit,
        NTILE(100) OVER (ORDER BY lifetime_profit DESC) AS profit_bucket
    FROM customer_summary
),
tiered AS (
    SELECT
        CASE
            WHEN profit_bucket <= 1  THEN 'Top 1%'
            WHEN profit_bucket <= 5  THEN 'Top 5%'
            WHEN profit_bucket <= 10 THEN 'Top 10%'
            WHEN profit_bucket <= 20 THEN 'Top 20%'
            ELSE 'Bottom 80%'
        END AS tier,
        CASE
            WHEN profit_bucket <= 1  THEN 1
            WHEN profit_bucket <= 5  THEN 2
            WHEN profit_bucket <= 10 THEN 3
            WHEN profit_bucket <= 20 THEN 4
            ELSE 5
        END AS tier_order,
        lifetime_profit
    FROM customer_ranked
)
SELECT
    tier,
    COUNT(*) AS customers,
    ROUND(SUM(lifetime_profit)::numeric, 2) AS band_profit,
    ROUND(
        (SUM(lifetime_profit) * 100.0 /
        SUM(SUM(lifetime_profit)) OVER ())::numeric,
        2
    ) AS band_profit_share_pct,
    ROUND((
        SUM(SUM(lifetime_profit)) OVER (ORDER BY tier_order) * 100.0 /
        SUM(SUM(lifetime_profit)) OVER ())::numeric,
        2
    ) AS cumulative_profit_share_pct
FROM tiered
GROUP BY tier, tier_order
ORDER BY tier_order;


/* results:

"tier","customers","band_profit","band_profit_share_pct","cumulative_profit_share_pct"
"Top 1%","495","9637581.29","8.35","8.35"
"Top 5%","1980","20593992.63","17.85","26.20"
"Top 10%","2475","16697437.32","14.47","40.67"
"Top 20%","4950","22517776.67","19.52","60.19"
"Bottom 80%","39587","45932816.12","39.81","100.00"


*/



-- ##### 2 - profit concentration by customer segment #####

select
    cseg.combined_segment,
    count(*) as customers,
    round(sum(cs.lifetime_profit)::numeric,2) as total_profit,
    round(
        (sum(cs.lifetime_profit)*100.0 /
        sum(sum(cs.lifetime_profit)) over())::numeric,2) as profit_share_pct
from customer_summary cs
join customer_segments cseg
    on cs.customerkey=cseg.customerkey
group by cseg.combined_segment
order by total_profit DESC


/* results:

"combined_segment","customers","total_profit","profit_share_pct"
"High-Value Stable","6720","40463924.28","35.07"
"High-Value At Risk","4159","25848272.47","22.40"
"Potential Loyalist","8290","16350843.80","14.17"
"Champions","1493","11377352.92","9.86"
"Needs Attention","11408","9223725.72","7.99"
"Loyal","4082","8932488.39","7.74"
"Low Priority","12345","2188976.13","1.90"
"Promising","963","984191.40","0.85"
"Budget Loyalist","27","9828.91","0.01"

*/


