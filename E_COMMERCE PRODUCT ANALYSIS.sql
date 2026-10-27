---Using JOINs across transactions and products, calculate monthly revenue, completed sales, refunds, cancellations, and net revenue by product category. 
--Use a CTE to structure the calculations and a window function to rank categories by monthly net revenue.

---AnSwers---

-- Revenue & Profitability Analysis
-- Monthly revenue, completed sales, refunds, cancellations,
-- and net revenue by product category
-- Using JOINs, CTEs, and Window Functions

WITH monthly_category_revenue AS (
    SELECT
        DATE_TRUNC('month', t.transaction_date)::DATE AS sales_month,
        p.category,
        SUM(CASE
            WHEN t.status = 'completed'
            THEN t.total_amount ELSE 0
        END) AS completed_revenue,
        COUNT(*) FILTER (
            WHERE t.status = 'completed'
        ) AS completed_sales,
        SUM(CASE
            WHEN t.status = 'refunded'
            THEN t.total_amount ELSE 0
        END) AS refunded_revenue,
        SUM(CASE
            WHEN t.status = 'cancelled'
            THEN t.total_amount ELSE 0
        END) AS cancelled_revenue
    FROM transactions t
    JOIN products p
        ON t.product_id = p.product_id
    GROUP BY
        DATE_TRUNC('month', t.transaction_date)::DATE,
        p.category
),
net_revenue AS (
    SELECT
        sales_month,
        category,
        completed_revenue,
        completed_sales,
        refunded_revenue,
        cancelled_revenue,
        completed_revenue
            - refunded_revenue AS net_revenue
    FROM monthly_category_revenue
)
SELECT
    sales_month,
    category,
    completed_revenue,
    completed_sales,
    refunded_revenue,
    cancelled_revenue,
    net_revenue,
    RANK() OVER (
        PARTITION BY sales_month
        ORDER BY net_revenue DESC
    ) AS category_revenue_rank
FROM net_revenue
ORDER BY
    sales_month,
    category_revenue_rank;

--------Customer Purchase Cohort Analysis: Join customers with transactions to identify signup-month cohorts. 
--Using CTEs and window functions, 
--calculate monthly customer retention, repeat-purchase rates, and cohort revenue trends.

---ANSWERS----

-- Customer Purchase Cohort Analysis
-- Monthly customer retention, repeat-purchase rates,
-- and cohort revenue trends

WITH customer_cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date)::DATE AS cohort_month
    FROM customers
),
customer_monthly_activity AS (
    SELECT
        t.customer_id,
        DATE_TRUNC('month', t.transaction_date)::DATE AS activity_month,
        COUNT(DISTINCT t.transaction_id) FILTER (
            WHERE t.status = 'completed'
        ) AS completed_purchases,
        SUM(t.total_amount) FILTER (
            WHERE t.status = 'completed'
        ) AS monthly_revenue
    FROM transactions t
    GROUP BY
        t.customer_id,
        DATE_TRUNC('month', t.transaction_date)::DATE
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        a.activity_month,
        (
            EXTRACT(YEAR FROM AGE(a.activity_month, c.cohort_month)) * 12
            + EXTRACT(MONTH FROM AGE(a.activity_month, c.cohort_month))
        )::INT AS cohort_age_month,
        a.customer_id,
        a.completed_purchases,
        COALESCE(a.monthly_revenue, 0) AS monthly_revenue
    FROM customer_cohorts c
    JOIN customer_monthly_activity a
        ON c.customer_id = a.customer_id
    WHERE a.activity_month >= c.cohort_month
),
cohort_monthly_metrics AS (
    SELECT
        cohort_month,
        activity_month,
        cohort_age_month,
        COUNT(DISTINCT customer_id) AS active_customers,
        COUNT(DISTINCT customer_id) FILTER (
            WHERE completed_purchases >= 2
        ) AS repeat_purchase_customers,
        SUM(completed_purchases) AS completed_purchase_count,
        SUM(monthly_revenue) AS cohort_revenue
    FROM cohort_activity
    GROUP BY
        cohort_month,
        activity_month,
        cohort_age_month
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
retention_metrics AS (
    SELECT
        m.cohort_month,
        m.activity_month,
        m.cohort_age_month,
        s.cohort_size,
        m.active_customers,
        m.repeat_purchase_customers,
        m.completed_purchase_count,
        m.cohort_revenue,
        ROUND(
            100.0 * m.active_customers
            / NULLIF(s.cohort_size, 0)::NUMERIC,
            2
        ) AS customer_retention_pct,
        ROUND(
            100.0 * m.repeat_purchase_customers
            / NULLIF(m.active_customers, 0)::NUMERIC,
            2
        ) AS repeat_purchase_rate_pct,
        LAG(m.cohort_revenue) OVER (
            PARTITION BY m.cohort_month
            ORDER BY m.activity_month
        ) AS previous_month_revenue
    FROM cohort_monthly_metrics m
    JOIN cohort_sizes s
        ON m.cohort_month = s.cohort_month
)
SELECT
    cohort_month,
    activity_month,
    cohort_age_month,
    cohort_size,
    active_customers,
    customer_retention_pct,
    repeat_purchase_customers,
    repeat_purchase_rate_pct,
    completed_purchase_count,
    cohort_revenue,
    previous_month_revenue,
    ROUND(
        (cohort_revenue - COALESCE(previous_month_revenue, 0))::NUMERIC,
        2
    ) AS revenue_change_from_previous_month
FROM retention_metrics
ORDER BY
    cohort_month,
    activity_month;


-------Customer Lifetime Value Ranking: Join customers, transactions, and products to calculate actual completed-purchase value per customer. 
--Compare it with the existing lifetime_value field and rank customers within each segment using RANK() or DENSE_RANK().

--ANSWERS---

-- Customer Lifetime Value Ranking
-- Calculate actual completed-purchase value per customer
-- Compare with existing lifetime_value
-- Rank customers within each segment

WITH actual_customer_value AS (
    SELECT
        c.customer_id,
        c.segment,
        c.lifetime_value AS existing_lifetime_value,
        COUNT(DISTINCT t.transaction_id) FILTER (
            WHERE t.status = 'completed'
        ) AS completed_purchase_count,
        COALESCE(
            SUM(t.total_amount) FILTER (
                WHERE t.status = 'completed'
            ),
            0
        ) AS actual_purchase_value
    FROM customers c
    LEFT JOIN transactions t
        ON c.customer_id = t.customer_id
    LEFT JOIN products p
        ON t.product_id = p.product_id
    GROUP BY
        c.customer_id,
        c.segment,
        c.lifetime_value
),
customer_ltv_comparison AS (
    SELECT
        customer_id,
        segment,
        completed_purchase_count,
        actual_purchase_value,
        existing_lifetime_value,
        actual_purchase_value - COALESCE(existing_lifetime_value, 0)
            AS value_difference,
        CASE
            WHEN existing_lifetime_value IS NULL
              OR existing_lifetime_value = 0
            THEN NULL
            ELSE ROUND(
                (
                    (actual_purchase_value - existing_lifetime_value)
                    / existing_lifetime_value
                )::NUMERIC * 100,
                2
            )
        END AS difference_pct
    FROM actual_customer_value
)
SELECT
    customer_id,
    segment,
    completed_purchase_count,
    ROUND(actual_purchase_value::NUMERIC, 2) AS actual_purchase_value,
    existing_lifetime_value,
    ROUND(value_difference::NUMERIC, 2) AS value_difference,
    difference_pct,
    RANK() OVER (
        PARTITION BY segment
        ORDER BY actual_purchase_value DESC
    ) AS customer_rank_in_segment
FROM customer_ltv_comparison
ORDER BY
    segment,
    customer_rank_in_segment;

--- Join customer churn labels with transaction history to calculate each customer’s historical purchase value, last purchase date, and purchase frequency. 
--Use CTEs and window functions to rank churned customers by historical revenue contribution and identify high-value churn exposure.  

---ANSWERS----

-- Churn Risk & Revenue Exposure
-- Historical purchase value, last purchase date, purchase frequency
-- Rank churned customers by historical revenue contribution

WITH customer_purchase_history AS (
    SELECT
        c.customer_id,
        c.segment,
        c.is_churned,
        c.lifetime_value,
        COUNT(DISTINCT t.transaction_id) FILTER (
            WHERE t.status = 'completed'
        ) AS purchase_frequency,
        COALESCE(
            SUM(t.total_amount) FILTER (
                WHERE t.status = 'completed'
            ),
            0
        ) AS historical_purchase_value,
        MAX(t.transaction_date) FILTER (
            WHERE t.status = 'completed'
        ) AS last_purchase_date
    FROM customers c
    LEFT JOIN transactions t
        ON c.customer_id = t.customer_id
    GROUP BY
        c.customer_id,
        c.segment,
        c.is_churned,
        c.lifetime_value
),
churn_revenue_exposure AS (
    SELECT
        customer_id,
        segment,
        is_churned,
        lifetime_value,
        purchase_frequency,
        historical_purchase_value,
        last_purchase_date,
        CURRENT_DATE - last_purchase_date::DATE
            AS days_since_last_purchase,
        SUM(historical_purchase_value) OVER (
            PARTITION BY is_churned
        ) AS total_revenue_by_churn_status,
        SUM(historical_purchase_value) OVER ()
            AS total_historical_revenue
    FROM customer_purchase_history
),
ranked_churn_customers AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY is_churned
            ORDER BY historical_purchase_value DESC
        ) AS revenue_rank,
        ROUND(
            100.0 * historical_purchase_value
            / NULLIF(total_historical_revenue, 0)::NUMERIC,
            2
        ) AS revenue_contribution_pct,
        ROUND(
            100.0 * historical_purchase_value
            / NULLIF(total_revenue_by_churn_status, 0)::NUMERIC,
            2
        ) AS churn_status_revenue_pct
    FROM churn_revenue_exposure
)
SELECT
    customer_id,
    segment,
    is_churned,
    purchase_frequency,
    ROUND(historical_purchase_value::NUMERIC, 2)
        AS historical_purchase_value,
    last_purchase_date,
    days_since_last_purchase,
    revenue_rank,
    revenue_contribution_pct,
    churn_status_revenue_pct,
    CASE
        WHEN is_churned = TRUE
             AND historical_purchase_value > 0
        THEN 'Churned Customer - Revenue Exposure'
        WHEN is_churned = TRUE
             AND historical_purchase_value = 0
        THEN 'Churned Customer - No Completed Revenue'
        ELSE 'Not Churned'
    END AS churn_exposure_category
FROM ranked_churn_customers
ORDER BY
    is_churned DESC,
    revenue_rank;

---Join sessions with customers and aggregate session activity by channel, device, and customer segment. 
--Use CTEs and `LAG()` to compare conversion rates across funnel stages where the available session data supports them, identifying the largest observed drop-offs.

---ANSWERS---

-- Conversion Funnel Drop-off Analysis
-- Aggregate sessions by channel, device, and customer segment
-- Use CTEs and LAG() to compare conversion rates across funnel stages

WITH session_metrics AS (
    SELECT
        s.channel,
        s.device,
        c.segment,
        COUNT(*) AS total_sessions,
        COUNT(*) FILTER (
            WHERE s.pages_viewed >= 1
        ) AS sessions_started,
        COUNT(*) FILTER (
            WHERE s.pages_viewed >= 3
        ) AS sessions_viewed_3plus_pages,
        COUNT(*) FILTER (
            WHERE s.cart_additions > 0
        ) AS sessions_with_cart_additions,
        COUNT(*) FILTER (
            WHERE s.converted = TRUE
        ) AS converted_sessions,
        COUNT(*) FILTER (
            WHERE s.bounced = TRUE
        ) AS bounced_sessions
    FROM sessions s
    JOIN customers c
        ON s.customer_id = c.customer_id
    GROUP BY
        s.channel,
        s.device,
        c.segment
),
funnel_stages AS (
    SELECT
        channel,
        device,
        segment,
        total_sessions,
        sessions_started,
        sessions_viewed_3plus_pages,
        sessions_with_cart_additions,
        converted_sessions,
        bounced_sessions,
        '01 - Session Started' AS funnel_stage,
        1 AS stage_order,
        sessions_started AS stage_sessions
    FROM session_metrics
    UNION ALL
    SELECT
        channel,
        device,
        segment,
        total_sessions,
        sessions_started,
        sessions_viewed_3plus_pages,
        sessions_with_cart_additions,
        converted_sessions,
        bounced_sessions,
        '02 - Viewed 3+ Pages',
        2,
        sessions_viewed_3plus_pages
    FROM session_metrics
    UNION ALL
    SELECT
        channel,
        device,
        segment,
        total_sessions,
        sessions_started,
        sessions_viewed_3plus_pages,
        sessions_with_cart_additions,
        converted_sessions,
        bounced_sessions,
        '03 - Added to Cart',
        3,
        sessions_with_cart_additions
    FROM session_metrics
    UNION ALL
    SELECT
        channel,
        device,
        segment,
        total_sessions,
        sessions_started,
        sessions_viewed_3plus_pages,
        sessions_with_cart_additions,
        converted_sessions,
        bounced_sessions,
        '04 - Converted',
        4,
        converted_sessions
    FROM session_metrics
),
stage_comparison AS (
    SELECT
        *,
        LAG(stage_sessions) OVER (
            PARTITION BY channel, device, segment
            ORDER BY stage_order
        ) AS previous_stage_sessions
    FROM funnel_stages
),
funnel_rates AS (
    SELECT
        *,
        ROUND(
            (
                100.0 * stage_sessions
                / NULLIF(total_sessions, 0)
            )::NUMERIC,
            2
        ) AS pct_of_total_sessions,
        ROUND(
            (
                100.0 * stage_sessions
                / NULLIF(previous_stage_sessions, 0)
            )::NUMERIC,
            2
        ) AS stage_conversion_rate_pct,
        ROUND(
            (
                100.0 * (
                    previous_stage_sessions - stage_sessions
                )
                / NULLIF(previous_stage_sessions, 0)
            )::NUMERIC,
            2
        ) AS drop_off_rate_pct,
        previous_stage_sessions - stage_sessions
            AS dropped_sessions
    FROM stage_comparison
)
SELECT
    channel,
    device,
    segment,
    funnel_stage,
    stage_order,
    total_sessions,
    stage_sessions,
    previous_stage_sessions,
    pct_of_total_sessions,
    stage_conversion_rate_pct,
    dropped_sessions,
    drop_off_rate_pct,
    bounced_sessions,
    RANK() OVER (
        PARTITION BY funnel_stage
        ORDER BY drop_off_rate_pct DESC NULLS LAST
    ) AS drop_off_rank
FROM funnel_rates
ORDER BY
    channel,
    device,
    segment,
    stage_order;

-- Analyze sessions by acquisition channel and device, joining customer segments where appropriate. 
--Use CTEs and window functions to rank channel-device combinations by conversion rate and session volume, identifying combinations with strong engagement but comparatively weak conversion.

---ANSWERS---

-- Marketing Channel Performance
-- Rank channel-device combinations by conversion rate and session volume
-- Identify strong engagement with comparatively weak conversion

WITH channel_device_metrics AS (
    SELECT
        s.channel,
        s.device,
        c.segment,
        COUNT(*) AS total_sessions,
        COUNT(*) FILTER (
            WHERE s.converted = TRUE
        ) AS converted_sessions,
        COUNT(*) FILTER (
            WHERE s.bounced = TRUE
        ) AS bounced_sessions,
        COUNT(*) FILTER (
            WHERE s.cart_additions > 0
        ) AS cart_sessions,
        ROUND(
            (
                100.0 * COUNT(*) FILTER (
                    WHERE s.converted = TRUE
                ) / NULLIF(COUNT(*), 0)
            )::NUMERIC,
            2
        ) AS conversion_rate_pct,

        ROUND(
            (
                100.0 * COUNT(*) FILTER (
                    WHERE s.bounced = TRUE
                ) / NULLIF(COUNT(*), 0)
            )::NUMERIC,
            2
        ) AS bounce_rate_pct,
        ROUND(
            (
                100.0 * COUNT(*) FILTER (
                    WHERE s.cart_additions > 0
                ) / NULLIF(COUNT(*), 0)
            )::NUMERIC,
            2
        ) AS cart_addition_rate_pct,
        ROUND(
            AVG(s.duration_seconds)::NUMERIC,
            2
        ) AS avg_session_duration_seconds,
        ROUND(
            AVG(s.pages_viewed)::NUMERIC,
            2
        ) AS avg_pages_viewed
    FROM sessions s
    JOIN customers c
        ON s.customer_id = c.customer_id
    GROUP BY
        s.channel,
        s.device,
        c.segment
),

ranked_metrics AS (
    SELECT
        *,

        RANK() OVER (
            PARTITION BY segment
            ORDER BY conversion_rate_pct DESC
        ) AS conversion_rate_rank,

        RANK() OVER (
            PARTITION BY segment
            ORDER BY total_sessions DESC
        ) AS session_volume_rank,

        AVG(conversion_rate_pct) OVER (
            PARTITION BY segment
        ) AS avg_segment_conversion_rate,

        AVG(total_sessions) OVER (
            PARTITION BY segment
        ) AS avg_segment_session_volume
    FROM channel_device_metrics
),
performance_classification AS (
    SELECT
        *,
        ROUND(
            (
                conversion_rate_pct - avg_segment_conversion_rate
            )::NUMERIC,
            2
        ) AS conversion_gap_pct_points,
        CASE
            WHEN avg_session_duration_seconds >=
                     AVG(avg_session_duration_seconds) OVER (
                         PARTITION BY segment
                     )
             AND avg_pages_viewed >=
                     AVG(avg_pages_viewed) OVER (
                         PARTITION BY segment
                     )
             AND conversion_rate_pct < avg_segment_conversion_rate
            THEN 'Strong Engagement, Weak Conversion'
            WHEN conversion_rate_pct >= avg_segment_conversion_rate
             AND total_sessions >= avg_segment_session_volume
            THEN 'Strong Conversion and Session Volume'
            WHEN total_sessions >= avg_segment_session_volume
             AND conversion_rate_pct < avg_segment_conversion_rate
            THEN 'High Traffic, Low Conversion'
            ELSE 'Other Performance'
        END AS performance_category
    FROM ranked_metrics
)
SELECT
    channel,
    device,
    segment,
    total_sessions,
    converted_sessions,
    conversion_rate_pct,
    conversion_rate_rank,
    session_volume_rank,
    bounced_sessions,
    bounce_rate_pct,
    cart_sessions,
    cart_addition_rate_pct,
    avg_session_duration_seconds,
    avg_pages_viewed,
    ROUND(avg_segment_conversion_rate::NUMERIC, 2)
        AS avg_segment_conversion_rate,
    conversion_gap_pct_points,
    performance_category
FROM performance_classification
ORDER BY
    segment,
    conversion_rate_rank,
    session_volume_rank;


--Join products with completed transactions to calculate revenue contribution by product. 
--Use a CTE and cumulative window functions to identify the products responsible for 80% of total completed transaction value, broken down by category.

---ANSWERS---

-- Product Revenue Contribution & 80% Pareto Analysis
-- Calculate completed transaction revenue by product and category
-- Use cumulative window functions to identify products contributing
-- to the first 80% of completed transaction value within each category

WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        COUNT(t.transaction_id) AS completed_transaction_count,
        SUM(t.total_amount) AS product_revenue
    FROM products p
    JOIN transactions t
        ON p.product_id = t.product_id
    WHERE t.status = 'completed'
    GROUP BY
        p.category,
        p.product_id,
        p.product_name
),
category_revenue AS (
    SELECT
        category,
        product_id,
        product_name,
        completed_transaction_count,
        product_revenue,
        SUM(product_revenue) OVER (
            PARTITION BY category
        ) AS category_total_revenue,
        SUM(product_revenue) OVER () AS overall_total_revenue
    FROM product_revenue
),
cumulative_revenue AS (
    SELECT
        *,
        SUM(product_revenue) OVER (
            PARTITION BY category
            ORDER BY product_revenue DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_category_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY product_revenue DESC, product_id
        ) AS product_revenue_rank
    FROM category_revenue
),
pareto_analysis AS (
    SELECT
        *,
        ROUND(
            (
                100.0 * product_revenue
                / NULLIF(category_total_revenue, 0)
            )::NUMERIC,
            2
        ) AS category_revenue_contribution_pct,
        ROUND(
            (
                100.0 * cumulative_category_revenue
                / NULLIF(category_total_revenue, 0)
            )::NUMERIC,
            2
        ) AS cumulative_category_revenue_pct,
        ROUND(
            (
                100.0 * product_revenue
                / NULLIF(overall_total_revenue, 0)
            )::NUMERIC,
            2
        ) AS overall_revenue_contribution_pct,
        CASE
            WHEN
                (
                    cumulative_category_revenue - product_revenue
                ) / NULLIF(category_total_revenue, 0) < 0.80
            THEN 'Within 80% Revenue Group'
            ELSE 'Beyond 80% Revenue Group'
        END AS pareto_category
    FROM cumulative_revenue
)
SELECT
    category,
    product_id,
    product_name,
    completed_transaction_count,
    ROUND(product_revenue::NUMERIC, 2) AS product_revenue,
    ROUND(category_total_revenue::NUMERIC, 2) AS category_total_revenue,
    category_revenue_contribution_pct,
    ROUND(cumulative_category_revenue::NUMERIC, 2)
        AS cumulative_category_revenue,
    cumulative_category_revenue_pct,
    overall_revenue_contribution_pct,
    product_revenue_rank,
    pareto_category
FROM pareto_analysis
ORDER BY
    category,
    product_revenue_rank;


----Join transactions with products and calculate monthly completed transaction value, transaction count, and unique purchasing customers. Use `LAG()` to calculate month-over-month growth and identify months with declining revenue or customer activity. 
--when writing keep in mind i am using pgadmin4  and no space between lines u give so much space

---ANSWERS---

-- Monthly Revenue and Customer Activity Trends
WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', t.transaction_date)::DATE AS sales_month,
        SUM(t.total_amount) AS monthly_revenue,
        COUNT(t.transaction_id) AS transaction_count,
        COUNT(DISTINCT t.customer_id) AS unique_customers
    FROM transactions t
    JOIN products p
        ON t.product_id = p.product_id
    WHERE t.status = 'completed'
    GROUP BY DATE_TRUNC('month', t.transaction_date)::DATE
),
monthly_growth AS (
    SELECT
        sales_month,
        monthly_revenue,
        transaction_count,
        unique_customers,
        LAG(monthly_revenue) OVER (ORDER BY sales_month) AS previous_month_revenue,
        LAG(transaction_count) OVER (ORDER BY sales_month) AS previous_month_transactions,
        LAG(unique_customers) OVER (ORDER BY sales_month) AS previous_month_customers
    FROM monthly_metrics
)
SELECT
    sales_month,
    ROUND(monthly_revenue::NUMERIC, 2) AS monthly_revenue,
    transaction_count,
    unique_customers,
    ROUND(previous_month_revenue::NUMERIC, 2) AS previous_month_revenue,
    ROUND(((monthly_revenue - previous_month_revenue) / NULLIF(previous_month_revenue, 0) * 100)::NUMERIC, 2) AS revenue_growth_pct,
    ROUND(((transaction_count - previous_month_transactions)::NUMERIC / NULLIF(previous_month_transactions, 0) * 100), 2) AS transaction_growth_pct,
    ROUND(((unique_customers - previous_month_customers)::NUMERIC / NULLIF(previous_month_customers, 0) * 100), 2) AS customer_growth_pct,
    CASE
        WHEN monthly_revenue < previous_month_revenue THEN 'Declining Revenue'
        ELSE 'Revenue Stable or Growing'
    END AS revenue_trend,
    CASE
        WHEN transaction_count < previous_month_transactions
          OR unique_customers < previous_month_customers
        THEN 'Declining Customer Activity'
        ELSE 'Customer Activity Stable or Growing'
    END AS customer_activity_trend
FROM monthly_growth
ORDER BY sales_month;

----Join customers with completed transactions to calculate recency, frequency, and monetary value. 
--Use CTEs and `NTILE()` or ranking window functions to classify customers into performance groups and compare their revenue contribution.

--ANSWERS---

-- RFM Analysis: Recency, Frequency, Monetary Value
WITH customer_rfm AS (
    SELECT
        c.customer_id,
        c.segment,
        c.is_churned,
        MAX(t.transaction_date)::DATE AS last_purchase_date,
        COUNT(DISTINCT t.transaction_id) AS frequency,
        COALESCE(SUM(t.total_amount), 0) AS monetary_value
    FROM customers c
    LEFT JOIN transactions t
        ON c.customer_id = t.customer_id
        AND t.status = 'completed'
    GROUP BY c.customer_id, c.segment, c.is_churned
),
rfm_metrics AS (
    SELECT
        customer_id,
        segment,
        is_churned,
        last_purchase_date,
        CASE
            WHEN last_purchase_date IS NULL THEN NULL
            ELSE CURRENT_DATE - last_purchase_date
        END AS recency_days,
        frequency,
        monetary_value
    FROM customer_rfm
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (
            ORDER BY recency_days DESC NULLS FIRST
        ) AS recency_score,
        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,
        NTILE(5) OVER (
            ORDER BY monetary_value ASC
        ) AS monetary_score
    FROM rfm_metrics
),
customer_groups AS (
    SELECT
        *,
        recency_score + frequency_score + monetary_score AS rfm_score,
        CASE
            WHEN recency_score + frequency_score + monetary_score >= 13 THEN 'High Value'
            WHEN recency_score + frequency_score + monetary_score >= 9 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS performance_group
    FROM rfm_scores
),
group_revenue AS (
    SELECT
        performance_group,
        COUNT(*) AS customer_count,
        SUM(frequency) AS total_completed_transactions,
        SUM(monetary_value) AS group_revenue,
        AVG(monetary_value) AS avg_customer_monetary_value,
        AVG(recency_days) AS avg_recency_days,
        SUM(SUM(monetary_value)) OVER () AS total_revenue
    FROM customer_groups
    GROUP BY performance_group
)
SELECT
    performance_group,
    customer_count,
    total_completed_transactions,
    ROUND(group_revenue::NUMERIC, 2) AS group_revenue,
    ROUND(avg_customer_monetary_value::NUMERIC, 2) AS avg_customer_monetary_value,
    ROUND(avg_recency_days::NUMERIC, 2) AS avg_recency_days,
    ROUND((100.0 * group_revenue / NULLIF(total_revenue, 0))::NUMERIC, 2) AS revenue_contribution_pct,
    RANK() OVER (ORDER BY group_revenue DESC) AS revenue_rank
FROM group_revenue
ORDER BY revenue_rank;

---Join products and transactions to compare discounted versus non-discounted completed purchases. 
---Use CTEs and window functions to analyze transaction value, quantity sold, and revenue by discount level and product category, highlighting patterns associated with discount usage.

---ANSWER---

-- Discount vs Non-Discounted Purchase Analysis
WITH transaction_analysis AS (
    SELECT
        p.category,
        CASE
            WHEN COALESCE(t.discount_applied, 0) > 0 THEN 'Discounted'
            ELSE 'Non-Discounted'
        END AS discount_level,
        COUNT(t.transaction_id) AS transaction_count,
        COUNT(DISTINCT t.customer_id) AS unique_customers,
        SUM(t.quantity) AS quantity_sold,
        SUM(t.total_amount) AS total_revenue,
        AVG(t.total_amount) AS avg_transaction_value,
        AVG(t.discount_applied) AS avg_discount_pct
    FROM transactions t
    JOIN products p
        ON t.product_id = p.product_id
    WHERE t.status = 'completed'
    GROUP BY
        p.category,
        CASE
            WHEN COALESCE(t.discount_applied, 0) > 0 THEN 'Discounted'
            ELSE 'Non-Discounted'
        END
),
category_comparison AS (
    SELECT
        *,
        SUM(total_revenue) OVER (
            PARTITION BY category
        ) AS category_total_revenue,
        SUM(quantity_sold) OVER (
            PARTITION BY category
        ) AS category_total_quantity,
        SUM(transaction_count) OVER (
            PARTITION BY category
        ) AS category_total_transactions,
        RANK() OVER (
            PARTITION BY category
            ORDER BY total_revenue DESC
        ) AS revenue_rank_within_category
    FROM transaction_analysis
),
discount_comparison AS (
    SELECT
        *,
        ROUND(
            (100.0 * total_revenue /
            NULLIF(category_total_revenue, 0))::NUMERIC,
            2
        ) AS category_revenue_contribution_pct,
        ROUND(
            (100.0 * quantity_sold /
            NULLIF(category_total_quantity, 0))::NUMERIC,
            2
        ) AS category_quantity_contribution_pct,
        ROUND(
            (100.0 * transaction_count /
            NULLIF(category_total_transactions, 0))::NUMERIC,
            2
        ) AS category_transaction_contribution_pct
    FROM category_comparison
)
SELECT
    category,
    discount_level,
    transaction_count,
    unique_customers,
    quantity_sold,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(avg_transaction_value::NUMERIC, 2) AS avg_transaction_value,
    ROUND(avg_discount_pct::NUMERIC, 2) AS avg_discount_pct,
    category_revenue_contribution_pct,
    category_quantity_contribution_pct,
    category_transaction_contribution_pct,
    revenue_rank_within_category,
    CASE
        WHEN discount_level = 'Discounted'
             AND category_revenue_contribution_pct >
                 category_transaction_contribution_pct
        THEN 'Higher Revenue Share than Transaction Share'
        WHEN discount_level = 'Discounted'
             AND category_quantity_contribution_pct >
                 category_revenue_contribution_pct
        THEN 'Higher Quantity Share than Revenue Share'
        WHEN discount_level = 'Non-Discounted'
             AND avg_transaction_value > 0
        THEN 'Non-Discounted Purchase Performance'
        ELSE 'Review Performance'
    END AS discount_performance_pattern
FROM discount_comparison
ORDER BY
    category,
    revenue_rank_within_category;


--Join products, reviews, and completed transactions to compare product ratings with sales volume and revenue. 
--Aggregate reviews and transactions separately before joining to prevent duplicate counting, then use ranking functions to identify high-rated, high-selling products and products with weaker sales despite strong ratings.

---ANSWER----

-- Product Ratings vs Sales Performance
WITH product_reviews AS (
    SELECT
        product_id,
        COUNT(review_id) AS review_count,
        ROUND(AVG(rating)::NUMERIC, 2) AS average_rating
    FROM reviews
    GROUP BY product_id
),
product_sales AS (
    SELECT
        product_id,
        COUNT(transaction_id) AS completed_transactions,
        COUNT(DISTINCT customer_id) AS unique_buyers,
        SUM(quantity) AS quantity_sold,
        SUM(total_amount) AS total_revenue
    FROM transactions
    WHERE status = 'completed'
    GROUP BY product_id
),
product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        COALESCE(r.review_count, 0) AS review_count,
        r.average_rating,
        COALESCE(s.completed_transactions, 0) AS completed_transactions,
        COALESCE(s.unique_buyers, 0) AS unique_buyers,
        COALESCE(s.quantity_sold, 0) AS quantity_sold,
        COALESCE(s.total_revenue, 0) AS total_revenue
    FROM products p
    LEFT JOIN product_reviews r
        ON p.product_id = r.product_id
    LEFT JOIN product_sales s
        ON p.product_id = s.product_id
),
ranked_products AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY average_rating DESC NULLS LAST
        ) AS rating_rank,
        RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS revenue_rank,
        RANK() OVER (
            ORDER BY quantity_sold DESC
        ) AS sales_volume_rank,
        AVG(total_revenue) OVER (
            PARTITION BY category
        ) AS category_avg_revenue,
        AVG(average_rating) OVER (
            PARTITION BY category
        ) AS category_avg_rating
    FROM product_performance
)
SELECT
    product_id,
    product_name,
    category,
    review_count,
    average_rating,
    completed_transactions,
    unique_buyers,
    quantity_sold,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    rating_rank,
    revenue_rank,
    sales_volume_rank,
    ROUND(category_avg_rating::NUMERIC, 2) AS category_avg_rating,
    ROUND(category_avg_revenue::NUMERIC, 2) AS category_avg_revenue,
    CASE
        WHEN average_rating >= 4
            AND total_revenue >= category_avg_revenue
            AND quantity_sold >= (
                SELECT AVG(quantity_sold)
                FROM product_performance pp
                WHERE pp.category = ranked_products.category
            )
        THEN 'High-Rated, High-Selling'
        WHEN average_rating >= 4
            AND total_revenue < category_avg_revenue
        THEN 'Strong Rating, Weaker Sales'
        WHEN average_rating < 3
            AND total_revenue >= category_avg_revenue
        THEN 'High Sales, Low Rating'
        WHEN average_rating IS NULL
        THEN 'No Reviews'
        ELSE 'Moderate Performance'
    END AS product_performance_category
FROM ranked_products
ORDER BY
    category,
    revenue_rank;

---Join customers with completed transactions and calculate monthly revenue, purchasing customers, and average transaction value for each segment. 
--Use `LAG()` and ranking functions to compare segment growth and identify segments contributing the most to revenue changes.

--ANSWER---

-- Monthly Revenue and Growth Analysis by Customer Segment
WITH monthly_segment_metrics AS (
    SELECT
        DATE_TRUNC('month', t.transaction_date)::DATE AS sales_month,
        c.segment,
        SUM(t.total_amount) AS monthly_revenue,
        COUNT(t.transaction_id) AS transaction_count,
        COUNT(DISTINCT t.customer_id) AS purchasing_customers,
        AVG(t.total_amount) AS avg_transaction_value
    FROM customers c
    JOIN transactions t
        ON c.customer_id = t.customer_id
    WHERE t.status = 'completed'
    GROUP BY
        DATE_TRUNC('month', t.transaction_date)::DATE,
        c.segment
),
segment_growth AS (
    SELECT
        sales_month,
        segment,
        monthly_revenue,
        transaction_count,
        purchasing_customers,
        avg_transaction_value,
        LAG(monthly_revenue) OVER (
            PARTITION BY segment
            ORDER BY sales_month
        ) AS previous_month_revenue,
        LAG(purchasing_customers) OVER (
            PARTITION BY segment
            ORDER BY sales_month
        ) AS previous_month_customers
    FROM monthly_segment_metrics
),
revenue_changes AS (
    SELECT
        *,
        monthly_revenue - COALESCE(previous_month_revenue, 0) AS revenue_change,
        purchasing_customers - COALESCE(previous_month_customers, 0) AS customer_change,
        ROUND(
            (
                (monthly_revenue - previous_month_revenue)
                / NULLIF(previous_month_revenue, 0) * 100
            )::NUMERIC,
            2
        ) AS revenue_growth_pct,
        ROUND(
            (
                (purchasing_customers - previous_month_customers)::NUMERIC
                / NULLIF(previous_month_customers, 0) * 100
            ),
            2
        ) AS customer_growth_pct
    FROM segment_growth
),
ranked_segments AS (
    SELECT
        *,
        SUM(monthly_revenue) OVER (
            PARTITION BY sales_month
        ) AS total_monthly_revenue,
        SUM(revenue_change) OVER (
            PARTITION BY sales_month
        ) AS total_revenue_change,
        RANK() OVER (
            PARTITION BY sales_month
            ORDER BY monthly_revenue DESC
        ) AS monthly_revenue_rank,
        RANK() OVER (
            PARTITION BY sales_month
            ORDER BY revenue_change DESC
        ) AS revenue_growth_contribution_rank
    FROM revenue_changes
)
SELECT
    sales_month,
    segment,
    ROUND(monthly_revenue::NUMERIC, 2) AS monthly_revenue,
    transaction_count,
    purchasing_customers,
    ROUND(avg_transaction_value::NUMERIC, 2) AS avg_transaction_value,
    ROUND(previous_month_revenue::NUMERIC, 2) AS previous_month_revenue,
    ROUND(revenue_change::NUMERIC, 2) AS revenue_change,
    revenue_growth_pct,
    previous_month_customers,
    customer_change,
    customer_growth_pct,
    ROUND(
        (
            100.0 * revenue_change
            / NULLIF(ABS(total_revenue_change), 0)
        )::NUMERIC,
        2
    ) AS revenue_change_contribution_pct,
    monthly_revenue_rank,
    revenue_growth_contribution_rank,
    CASE
        WHEN revenue_change < 0 THEN 'Declining Revenue'
        WHEN revenue_change > 0 THEN 'Growing Revenue'
        ELSE 'No Revenue Change'
    END AS revenue_trend,
    CASE
        WHEN customer_change < 0 THEN 'Declining Customers'
        WHEN customer_change > 0 THEN 'Growing Customers'
        ELSE 'No Customer Change'
    END AS customer_activity_trend
FROM ranked_segments
ORDER BY
    sales_month,
    revenue_growth_contribution_rank;