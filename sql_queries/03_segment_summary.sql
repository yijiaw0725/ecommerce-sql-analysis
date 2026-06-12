/*
=============================================================================
Segment Summary
Author: [Yijia]
Description:
Rolls the per-customer RFM segmentation (02_rfm_segmentation.sql) up to one
row per segment: customer count, share of customers, revenue, share of
revenue, average spend, and average days since last purchase.
This is the query behind the "Key findings" table in the README.
=============================================================================
*/

WITH rfm_raw AS (
SELECT
c.customer_unique_id,
CAST(
JULIANDAY('2018-09-01') - JULIANDAY(MAX(o.order_purchase_timestamp))
AS INTEGER) AS recency_days,
COUNT(DISTINCT o.order_id) AS frequency,
SUM(p.payment_value) AS monetary
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
),

rfm_scores AS (
SELECT
*,
NTILE(5) OVER (ORDER BY recency_days DESC) as r_score,
NTILE(5) OVER (ORDER BY frequency ASC, monetary ASC) as f_score,
NTILE(5) OVER (ORDER BY monetary ASC) as m_score
FROM rfm_raw
),

rfm_segments AS (
SELECT
*,
CASE
WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Best'
WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
WHEN recency_days <= 90 AND frequency = 1 THEN 'New & Promising'
WHEN r_score <= 2 AND m_score >= 3 THEN 'At Risk'
ELSE 'Standard'
END AS customer_segment
FROM rfm_scores
)

SELECT
customer_segment,
COUNT(*) AS customers,
ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers,
ROUND(SUM(monetary), 0) AS revenue,
ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue,
ROUND(AVG(monetary), 0) AS avg_spend,
ROUND(AVG(recency_days), 0) AS avg_recency_days
FROM rfm_segments
GROUP BY customer_segment
ORDER BY revenue DESC;
