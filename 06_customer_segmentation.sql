-- Lets classify the customers using RFM standard naming:


-- Classification view:

CREATE or REPLACE VIEW customer_segments as
with base as (
    SELECT
        r.customerkey,
        r.recency_score,
        r.frequency_score,
        r.monetary_score,
        r.rfm_total_score,
        v.value_segment
    FROM rfm_scores r
    JOIN customer_value_segments v
    ON r.customerkey = v.customerkey
)

Select
    *,
    CASE

        WHEN value_segment = 'High Value' AND recency_score >= 4 AND frequency_score >= 4 THEN 'Champions'
        WHEN value_segment = 'High Value' AND recency_score <= 2 THEN 'High-Value At Risk'
        WHEN value_segment = 'High Value' THEN 'High-Value Stable'

        WHEN value_segment = 'Mid-High Value' AND rfm_total_score >= 10 THEN 'Loyal'
        WHEN value_segment = 'Mid-High Value' THEN 'Potential Loyalist'

        WHEN value_segment = 'Low-Mid Value' AND rfm_total_score >= 10 THEN 'Promising'
        WHEN value_segment = 'Low-Mid Value' THEN 'Needs Attention'

        WHEN value_segment = 'Low Value' AND rfm_total_score >= 10 THEN 'Budget Loyalist'

        ELSE 'Low Priority'

    END AS combined_segment


FROM base;



--------- SUMMARIES:--------------
-- segments size:

SELECT
    combined_segment,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),2) AS pct_customers
FROM customer_segments
GROUP BY combined_segment
ORDER BY customers DESC;

/* results:

"combined_segment","customers","pct_customers"
"Low Priority","12345","24.95"
"Needs Attention","11408","23.05"
"Potential Loyalist","8290","16.75"
"High-Value Stable","6720","13.58"
"High-Value At Risk","4159","8.40"
"Loyal","4082","8.25"
"Champions","1493","3.02"
"Promising","963","1.95"
"Budget Loyalist","27","0.05"

*/


-- profit by segment:

SELECT
    combined_segment,
    COUNT(*) AS customers,
    ROUND(AVG(csum.lifetime_profit)::numeric,2) AS avg_profit,
    ROUND(SUM(csum.lifetime_profit)::numeric,2) AS total_profit,
    ROUND((SUM(csum.lifetime_profit)*100.0/SUM(SUM(csum.lifetime_profit)) over())::numeric,2) as pct_profit
FROM customer_segments cseg
JOIN customer_summary csum
ON cseg.customerkey = csum.customerkey
GROUP BY combined_segment
ORDER BY total_profit DESC;


/* reuslts:

"combined_segment","customers","avg_profit","total_profit"
"High-Value Stable","6720","6021.42","40463924.28"
"High-Value At Risk","4159","6215.02","25848272.47"
"Potential Loyalist","8290","1972.36","16350843.80"
"Champions","1493","7620.46","11377352.92"
"Needs Attention","11408","808.53","9223725.72"
"Loyal","4082","2188.26","8932488.39"
"Low Priority","12345","177.32","2188976.13"
"Promising","963","1022.01","984191.40"
"Budget Loyalist","27","364.03","9828.91"

*/


-- Revenue by segment:

SELECT
    combined_segment,
    ROUND(AVG(csum.lifetime_revenue)::numeric,2) AS avg_revenue,
    ROUND(SUM(csum.lifetime_revenue)::numeric,2) AS total_revenue
FROM customer_segments cseg
JOIN customer_summary csum
    ON cseg.customerkey = csum.customerkey
GROUP BY combined_segment
ORDER BY total_revenue DESC;

/* results:

"combined_segment","avg_revenue","total_revenue"
"High-Value Stable","10446.63","70201360.70"
"High-Value At Risk","10786.42","44860701.94"
"Potential Loyalist","3660.01","30341498.08"
"Champions","13511.75","20173049.26"
"Needs Attention","1547.67","17655779.90"
"Loyal","4111.62","16783642.85"
"Low Priority","350.15","4322554.38"
"Promising","1988.35","1914783.84"
"Budget Loyalist","732.43","19775.50"

*/
