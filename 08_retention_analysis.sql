-- Lets analyze the customer base more in depth
-- This section will try to answer a few questions:
    --Which customers have not purchased recently?
    --How many customers are inactive at different thresholds?
    --Which inactive customers are the most important financially?
    --Which segments contain the most at-risk profit?

--This dataset is not current, so again, i will use its max orderdate as reference



--#### 1- Customer Inactivity classification ####--

CREATE OR REPLACE VIEW customer_retention_status AS
SELECT
    cs.customerkey,
    cs.customer_country,
    cs.last_purchase_date,
    cs.recency_days,
    cs.lifetime_revenue,
    cs.lifetime_profit,
    cs.order_count,
    CASE
        WHEN cs.recency_days <= 30 THEN 'Active'
        WHEN cs.recency_days <= 90 THEN 'Cooling'
        WHEN cs.recency_days <= 180 THEN 'Inactive'
        ELSE 'Churned'
    END AS retention_status
FROM customer_summary cs;



--#### 2- Summary by inactivity band - retention summary ####--

SELECT
    retention_status,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_customers,
    ROUND(SUM(lifetime_revenue)::numeric, 2) AS total_revenue,
    ROUND(SUM(lifetime_profit)::numeric, 2) AS total_profit
FROM customer_retention_status
GROUP BY retention_status
ORDER BY
    CASE retention_status
        WHEN 'Active' THEN 1
        WHEN 'Cooling' THEN 2
        WHEN 'Inactive' THEN 3
        WHEN 'Churned' THEN 4
    END;


/* results:

"retention_status","customers","pct_customers","total_revenue","total_profit"
"Active","407","0.82","1989146.76","1112149.40"
"Inactive","3714","7.51","17058171.74","9557910.70"
"Churned","42575","86.03","173594804.22","97092974.52"
"Cooling","2791","5.64","13631023.73","7616569.40"

*/



--#### 3- High-value or profit customers at risk ####--
-- most valuable inactive customers


--3.1 - Recoverable high-value customers
SELECT
    customerkey,
    customer_country,
    first_purchase_date,
    last_purchase_date,
    recency_days,
    order_count,
    lifetime_revenue,
    lifetime_profit
FROM customer_summary
WHERE recency_days BETWEEN 90 AND 365
ORDER BY lifetime_profit DESC
LIMIT 25;

--3.2 - valuable but likely lost customers

SELECT
    customerkey,
    customer_country,
    first_purchase_date,
    last_purchase_date,
    recency_days,
    order_count,
    lifetime_revenue,
    lifetime_profit
FROM customer_summary
WHERE recency_days > 365
ORDER BY lifetime_profit DESC
LIMIT 25;



--#### 4- At-risk customers by segment ####--

SELECT
    cseg.combined_segment,
    crs.retention_status,
    COUNT(*) AS customers,
    ROUND(SUM(crs.lifetime_profit)::numeric, 2) AS total_profit,
    ROUND((SUM(crs.lifetime_profit) * 100.0 / SUM(SUM(crs.lifetime_profit)) OVER ())::numeric,2) AS profit_share_pct
FROM customer_retention_status crs
JOIN customer_segments cseg
    ON crs.customerkey = cseg.customerkey
GROUP BY
    cseg.combined_segment,
    crs.retention_status
ORDER BY total_profit DESC;




-- same query but ordered by segment and retention status for the readme:

SELECT
    cseg.combined_segment,
    crs.retention_status,
    COUNT(*) AS customers,
    ROUND(SUM(crs.lifetime_profit)::numeric, 2) AS total_profit,
    ROUND((SUM(crs.lifetime_profit) * 100.0 / SUM(SUM(crs.lifetime_profit)) OVER ())::numeric,2) AS profit_share_pct
FROM customer_retention_status crs
JOIN customer_segments cseg
    ON crs.customerkey = cseg.customerkey
GROUP BY
    cseg.combined_segment,
    crs.retention_status
ORDER BY
    CASE cseg.combined_segment
        WHEN 'Champions' THEN 1
        WHEN 'High-Value Stable' THEN 2
        WHEN 'High-Value At Risk' THEN 3
        WHEN 'Loyal' THEN 4
        WHEN 'Potential Loyalist' THEN 5
        WHEN 'Promising' THEN 6
        WHEN 'Needs Attention' THEN 7
        WHEN 'Budget Loyalist' THEN 8
        WHEN 'Low Priority' THEN 9
    END,
    CASE crs.retention_status
        WHEN 'Active' THEN 1
        WHEN 'Cooling' THEN 2
        WHEN 'Inactive' THEN 3
        WHEN 'Churned' THEN 4
    END;

--#### 5- Country-level retention breakdown ####--


SELECT
    customer_country,
    retention_status,
    COUNT(*) AS customers,
    ROUND(AVG(recency_days)::numeric,0) AS avg_recency_days,
    ROUND(SUM(lifetime_profit)::numeric,2) AS total_profit
FROM customer_retention_status
GROUP BY customer_country, retention_status
ORDER BY
    customer_country,
    CASE retention_status
        WHEN 'Active' THEN 1
        WHEN 'Cooling' THEN 2
        WHEN 'Inactive' THEN 3
        WHEN 'Churned' THEN 4
    END;


