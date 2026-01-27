-- Exploratory Data Analysis
-- Goal: Confirm time range of our data

SELECT
MIN(order_purchase_timestamp) AS first_order_date,
MAX(order_purchase_timestamp) AS last_order_date,
COUNT(*) AS total_orders
FROM orders;

-- Goal: check distribution of payment method
SELECT
payment_type,
COUNT(*) as usage_count,
ROUND(AVG(payment_value), 2) as avg_transaction_value
FROM payments
GROUP BY payment_type
ORDER BY usage_count DESC;
