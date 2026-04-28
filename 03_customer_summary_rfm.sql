-- In here the goal is to agg orders to one row per customer.
-- With this I will get metrics for each customer

CREATE OR REPLACE VIEW customer_summary as

with customer_agg as (
    SELECT
        customerkey,

        min(orderdate) as first_purchase_date,
        max(orderdate) as last_purchase_date,

        count(distinct orderkey) as order_count,
        sum(total_units) as total_units,
        sum(order_revenue) as lifetime_revenue,
        sum(order_cost) as lifetime_cost,
        sum(order_profit) as lifetime_profit
    From order_enriched
    Group by customerkey
),

last_date as (
    SELECT
        max(orderdate) as dataset_last_date
    from order_enriched
)

select
    ca.customerkey,

    c.countryfull as customer_country,
    c.gender,
    c.occupation,

    ca.first_purchase_date,
    ca.last_purchase_date,
    ca.last_purchase_date - ca.first_purchase_date as customer_lifespan_days,

    ca.order_count,
    ca.total_units,

    ca.lifetime_revenue,
    ca.lifetime_cost,
    ca.lifetime_profit,
    ca.lifetime_revenue/NULLIF(ca.order_count,0) as avg_order_value,
    ca.lifetime_profit/NULLIF(ca.order_count,0) AS avg_order_profit,
    ca.lifetime_profit/NULLIF(ca.lifetime_revenue,0) AS profit_margin,

    ld.dataset_last_date - ca.last_purchase_date as recency_days,

    DATE_TRUNC('month', ca.first_purchase_date) AS cohort_month,
    EXTRACT(YEAR FROM ca.first_purchase_date) as cohort_year,

    DATE_part('year', AGE(ca.first_purchase_date,birthday)) AS age_at_first_purchase 

from customer_agg ca
inner join customer c on ca.customerkey=c.customerkey
CROSS JOIN last_date ld;



