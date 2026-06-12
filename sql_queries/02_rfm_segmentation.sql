/*
=============================================================================
Project Name: RFM Customer Segmentation
Author: [Yijia]
Description:
In this project, I built a model based on RFM (Recency, Frequency, Monetary).

Core Tech:
1. Common Table Expressions (CTEs)
2. Window Functions (NTILE): segment customers into level 1-5.
3. JOINs: Join three core tables (Orders, Customers, Payments).
=============================================================================
*/

-- 1. Calculate each customer's R, F, M values
WITH rfm_raw AS (
SELECT
c.customer_unique_id,
-- R (Recency): How many days away from previous purchase
-- Use JulianDay to calculate date difference, use 2018-09-01 to mimic the date of analysis.
CAST(
JULIANDAY('2018-09-01') - JULIANDAY(MAX(o.order_purchase_timestamp))
AS INTEGER) AS recency_days,

-- F (Frequency): how many times of purchase
COUNT(DISTINCT o.order_id) AS frequency,

-- M (Monetary): total money spent
SUM(p.payment_value) AS monetary
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered' -- only focus on delivered orders
GROUP BY c.customer_unique_id
),

-- 2. use window functions to score customers (from 1-5 with 5 highest)
rfm_scores AS (
SELECT
*,
-- R: bigger date diff (longer since last purchase) = lower score. So big day diff goes in Bucket 1, small day diff in Bucket 5.
NTILE(5) OVER (ORDER BY recency_days DESC) as r_score,
-- F: higher score for more times of purchase.
-- 97% of customers bought exactly once, so frequency alone has massive ties and
-- NTILE would split them arbitrarily. Use monetary as a tie-breaker: among customers
-- with the same frequency, higher spenders get the higher score.
NTILE(5) OVER (ORDER BY frequency ASC, monetary ASC) as f_score,
-- M: higher score for more total money spent
NTILE(5) OVER (ORDER BY monetary ASC) as m_score
FROM rfm_raw
)

-- 3. Final output: combine and segment customers
SELECT
customer_unique_id,
recency_days,
frequency,
monetary,
r_score,
f_score,
m_score,
-- joined score: "555" would be a top customer
(r_score || f_score || m_score) as rfm_cell,
-- Use business logic to segment
CASE
-- recent + frequent + high spend on all three dimensions
WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Best'
-- solid on all three dimensions, just not top-tier
WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
-- first purchase within the last 90 days: too early to judge, worth nurturing
WHEN recency_days <= 90 AND frequency = 1 THEN 'New & Promising'
-- went quiet (bottom 40% on recency) but used to spend decently: worth winning back.
-- The m_score filter keeps this segment actionable instead of lumping in every lapsed low-spender.
WHEN r_score <= 2 AND m_score >= 3 THEN 'At Risk'
ELSE 'Standard'
END AS customer_segment
FROM rfm_scores
ORDER BY monetary DESC;