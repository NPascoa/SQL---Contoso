-- In this section I want to test some of the patterns I've observed, wether they are statistically
--meaningful. 


-- ##### 12.1 Average Order Value difference across customer segments:

--Do different customer segments generate different average order values (AOV)?

--If segmentation is meaningful, higher-value segments should show significantly larger order values.

--H0 - Average order value is the same across all customer segments.
--H1 - At least one segment has a different average order value.

SELECT
    cseg.combined_segment,
    oe.order_revenue
FROM order_enriched oe
JOIN customer_segments cseg
    ON oe.customerkey = cseg.customerkey
WHERE oe.order_revenue IS NOT NULL;



-- ##### 12.2 Delivery time differences across countries:

--Does delivery performance vary meaningfully across countries?

--Earlier analysis showed that delivery times appear similar across markets, but statistical testing can confirm whether the observed differences are meaningful.

--HO - Average delivery time is the same across all countries.
--H1 - At least one country has a different average delivery time.


SELECT
    customer_country,
    delivery_days
FROM order_enriched
WHERE delivery_days IS NOT NULL;