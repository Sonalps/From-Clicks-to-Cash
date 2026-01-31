-- FILE: 02_revenue_trends.sql (UPDATED AFTER DATA VALIDATION)
-- PURPOSE: Calculate monthly and quarterly revenue trends
-- FILTERS APPLIED: 
--   - Exclude Cancelled & Returned orders (15% + 10% = 25% of orders)
--   - Date range: 2019-2024 only (exclude future dates)
--   - Focus on Complete & Shipped orders (actual revenue)

-- QUERY 1: Monthly Revenue Trends with Growth Metrics
-- ----------------------------------------------------------------------------
WITH monthly_revenue AS (
  SELECT 
    DATE_TRUNC('month', oi.created_at) as month,
    COUNT(DISTINCT oi.order_id) as total_orders,
    COUNT(DISTINCT oi.id) as total_items,
    SUM(oi.sale_price) as total_revenue,
    AVG(oi.sale_price) as avg_item_price,
    COUNT(DISTINCT oi.user_id) as unique_customers
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')  -- Only revenue-generating orders
    AND oi.created_at >= '2019-01-01' 
    AND oi.created_at < '2025-01-01'  -- Exclude future dates
  GROUP BY 1
)
SELECT 
  month,
  total_orders,
  total_items,
  ROUND(total_revenue::numeric, 2) as total_revenue,
  ROUND(avg_item_price::numeric, 2) as avg_item_price,
  unique_customers,
  ROUND((total_revenue / total_orders)::numeric, 2) as avg_order_value,
  ROUND((total_items::numeric / total_orders), 2) as items_per_order,
  -- Month-over-month growth
  ROUND(100.0 * (total_revenue - LAG(total_revenue) OVER (ORDER BY month)) / 
    NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0), 2) as mom_revenue_growth_pct,
  ROUND(100.0 * (total_orders - LAG(total_orders) OVER (ORDER BY month)) / 
    NULLIF(LAG(total_orders) OVER (ORDER BY month), 0), 2) as mom_orders_growth_pct,
  -- Year-over-year growth
  ROUND(100.0 * (total_revenue - LAG(total_revenue, 12) OVER (ORDER BY month)) / 
    NULLIF(LAG(total_revenue, 12) OVER (ORDER BY month), 0), 2) as yoy_revenue_growth_pct
FROM monthly_revenue
ORDER BY month;

-- QUERY 2: Quarterly Revenue Summary

WITH quarterly_data AS (
  SELECT 
    DATE_TRUNC('quarter', oi.created_at) as quarter,
    SUM(oi.sale_price) as revenue,
    COUNT(DISTINCT oi.order_id) as orders,
    COUNT(DISTINCT oi.user_id) as customers
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND oi.created_at >= '2019-01-01' 
    AND oi.created_at < '2025-01-01'
  GROUP BY 1
)
SELECT 
  quarter,
  orders as total_orders,
  customers as unique_customers,
  ROUND(revenue::numeric, 2) as total_revenue,
  ROUND((revenue / orders)::numeric, 2) as avg_order_value,
  ROUND((revenue / customers)::numeric, 2) as revenue_per_customer,
  ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY quarter)) / 
    NULLIF(LAG(revenue) OVER (ORDER BY quarter), 0), 2) as qoq_growth_pct,
  ROUND(100.0 * (revenue - LAG(revenue, 4) OVER (ORDER BY quarter)) / 
    NULLIF(LAG(revenue, 4) OVER (ORDER BY quarter), 0), 2) as yoy_growth_pct
FROM quarterly_data
ORDER BY quarter;

-- QUERY 3: Annual Revenue Summary (Year-over-Year Comparison)
-- ----------------------------------------------------------------------------
SELECT 
  EXTRACT(YEAR FROM oi.created_at) as year,
  COUNT(DISTINCT oi.order_id) as total_orders,
  COUNT(DISTINCT oi.id) as total_items,
  COUNT(DISTINCT oi.user_id) as unique_customers,
  ROUND(SUM(oi.sale_price)::numeric, 2) as total_revenue,
  ROUND(AVG(oi.sale_price)::numeric, 2) as avg_item_price,
  ROUND((SUM(oi.sale_price) / COUNT(DISTINCT oi.order_id))::numeric, 2) as avg_order_value,
  ROUND((COUNT(DISTINCT oi.id)::numeric / COUNT(DISTINCT oi.order_id)), 2) as items_per_order,
  ROUND((SUM(oi.sale_price) / COUNT(DISTINCT oi.user_id))::numeric, 2) as revenue_per_customer
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('Complete', 'Shipped')
  AND oi.created_at >= '2019-01-01' 
  AND oi.created_at < '2025-01-01'
GROUP BY 1
ORDER BY 1;

-- QUERY 4: Revenue by Order Status (Understanding Revenue Leakage)
-- ----------------------------------------------------------------------------
SELECT 
  o.status,
  COUNT(DISTINCT o.order_id) as order_count,
  ROUND(100.0 * COUNT(DISTINCT o.order_id) / SUM(COUNT(DISTINCT o.order_id)) OVER (), 2) as pct_of_orders,
  COUNT(DISTINCT oi.id) as item_count,
  ROUND(SUM(oi.sale_price)::numeric, 2) as potential_revenue,
  ROUND(100.0 * SUM(oi.sale_price) / SUM(SUM(oi.sale_price)) OVER (), 2) as pct_of_potential_revenue,
  ROUND((SUM(oi.sale_price) / COUNT(DISTINCT o.order_id))::numeric, 2) as avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.created_at >= '2019-01-01' 
  AND o.created_at < '2025-01-01'
GROUP BY o.status
ORDER BY potential_revenue DESC;

-- QUERY 5: Monthly Revenue by Status (Track Processing Pipeline)
-- ----------------------------------------------------------------------------
SELECT 
  DATE_TRUNC('month', o.created_at) as month,
  o.status,
  COUNT(DISTINCT o.order_id) as orders,
  ROUND(SUM(oi.sale_price)::numeric, 2) as revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.created_at >= '2023-01-01'  -- Last 2 years for trend
  AND o.created_at < '2025-01-01'
GROUP BY 1, 2
ORDER BY 1 DESC, 4 DESC;

-- QUERY 7: Seasonality Analysis (Monthly Patterns Across Years)
-- ----------------------------------------------------------------------------
-- QUERY 7: Seasonality Analysis (Monthly Patterns Across Years)
-- ----------------------------------------------------------------------------
SELECT 
  EXTRACT(MONTH FROM oi.created_at) AS month_number,
  TO_CHAR(DATE '2024-01-01' + (EXTRACT(MONTH FROM oi.created_at) - 1) * INTERVAL '1 month', 'Month') AS month_name,
  COUNT(DISTINCT oi.order_id) AS total_orders,
  ROUND(SUM(oi.sale_price)::numeric, 2) AS total_revenue,
  ROUND((SUM(oi.sale_price) / NULLIF(COUNT(DISTINCT oi.order_id), 0))::numeric, 2) AS avg_order_value,
  -- Year-over-year comparison (most recent years)
  ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2023 THEN oi.sale_price ELSE 0 END)::numeric, 2) AS revenue_2023,
  ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2024 THEN oi.sale_price ELSE 0 END)::numeric, 2) AS revenue_2024,
  -- YoY growth percentage
  ROUND(100.0 * (
    SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2024 THEN oi.sale_price ELSE 0 END) -
    SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2023 THEN oi.sale_price ELSE 0 END)
  ) / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2023 THEN oi.sale_price ELSE 0 END), 0), 2) AS yoy_growth_pct
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('Complete', 'Shipped')
  AND oi.created_at >= '2019-01-01' 
  AND oi.created_at < '2025-01-01'
GROUP BY 1
ORDER BY 1;

-- QUERY 8: Revenue Velocity (How Fast Are We Growing?)
-- ----------------------------------------------------------------------------
WITH monthly_metrics AS (
  SELECT 
    DATE_TRUNC('month', oi.created_at) AS month,
    SUM(oi.sale_price) AS revenue
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND oi.created_at >= '2019-01-01' 
    AND oi.created_at < '2025-01-01'
  GROUP BY 1
)
SELECT 
  month,
  ROUND(revenue::numeric, 2) AS current_revenue,
  ROUND(100.0 * (revenue - LAG(revenue, 1) OVER (ORDER BY month)) / 
    NULLIF(LAG(revenue, 1) OVER (ORDER BY month), 0), 2) AS mom_growth_pct,
  ROUND(100.0 * (revenue - LAG(revenue, 12) OVER (ORDER BY month)) / 
    NULLIF(LAG(revenue, 12) OVER (ORDER BY month), 0), 2) AS yoy_growth_pct
FROM monthly_metrics
WHERE month >= '2020-01-01'
ORDER BY month DESC;


-- QUERY 9: Revenue Summary - Executive Dashboard KPIs
-- ----------------------------------------------------------------------------
WITH latest_complete_month AS (
  SELECT DATE_TRUNC('month', MAX(created_at)) - INTERVAL '1 month' as month
  FROM orders
  WHERE created_at < '2025-01-01'
),
current_month AS (
  SELECT 
    COUNT(DISTINCT oi.order_id) as orders,
    ROUND(SUM(oi.sale_price)::numeric, 2) as revenue,
    COUNT(DISTINCT oi.user_id) as customers,
    ROUND(AVG(oi.sale_price)::numeric, 2) as avg_item_price,
    ROUND((SUM(oi.sale_price) / COUNT(DISTINCT oi.order_id))::numeric, 2) as aov
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  CROSS JOIN latest_complete_month
  WHERE o.status IN ('Complete', 'Shipped')
    AND DATE_TRUNC('month', o.created_at) = latest_complete_month.month
),
prior_month AS (
  SELECT 
    COUNT(DISTINCT oi.order_id) as orders,
    ROUND(SUM(oi.sale_price)::numeric, 2) as revenue,
    COUNT(DISTINCT oi.user_id) as customers,
    ROUND(AVG(oi.sale_price)::numeric, 2) as avg_item_price,
    ROUND((SUM(oi.sale_price) / COUNT(DISTINCT oi.order_id))::numeric, 2) as aov
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  CROSS JOIN latest_complete_month
  WHERE o.status IN ('Complete', 'Shipped')
    AND DATE_TRUNC('month', o.created_at) = latest_complete_month.month - INTERVAL '1 month'
),
year_ago AS (
  SELECT 
    ROUND(SUM(oi.sale_price)::numeric, 2) as revenue
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  CROSS JOIN latest_complete_month
  WHERE o.status IN ('Complete', 'Shipped')
    AND DATE_TRUNC('month', o.created_at) = latest_complete_month.month - INTERVAL '12 months'
)
SELECT 
  'Total Revenue' as kpi_name,
  curr.revenue as current_value,
  prior.revenue as prior_month_value,
  year_ago.revenue as year_ago_value,
  ROUND(100.0 * (curr.revenue - prior.revenue) / NULLIF(prior.revenue, 0), 2) as mom_change_pct,
  ROUND(100.0 * (curr.revenue - year_ago.revenue) / NULLIF(year_ago.revenue, 0), 2) as yoy_change_pct
FROM current_month curr, prior_month prior, year_ago
UNION ALL
SELECT 
  'Total Orders',
  curr.orders,
  prior.orders,
  NULL,
  ROUND(100.0 * (curr.orders - prior.orders) / NULLIF(prior.orders::numeric, 0), 2),
  NULL
FROM current_month curr, prior_month prior, year_ago
UNION ALL
SELECT 
  'Unique Customers',
  curr.customers,
  prior.customers,
  NULL,
  ROUND(100.0 * (curr.customers - prior.customers) / NULLIF(prior.customers::numeric, 0), 2),
  NULL
FROM current_month curr, prior_month prior, year_ago
UNION ALL
SELECT 
  'Average Order Value',
  curr.aov,
  prior.aov,
  NULL,
  ROUND(100.0 * (curr.aov - prior.aov) / NULLIF(prior.aov, 0), 2),
  NULL
FROM current_month curr, prior_month prior, year_ago;


-- QUERY 10: Cancelled Orders Analysis (Revenue Leakage Deep Dive)
-- ----------------------------------------------------------------------------
SELECT 
  DATE_TRUNC('month', o.created_at) as month,
  -- Completed revenue
  ROUND(SUM(CASE WHEN o.status IN ('Complete', 'Shipped') THEN oi.sale_price ELSE 0 END)::numeric, 2) 
    as realized_revenue,
  -- Lost revenue (Cancelled)
  ROUND(SUM(CASE WHEN o.status = 'Cancelled' THEN oi.sale_price ELSE 0 END)::numeric, 2) 
    as cancelled_revenue,
  -- Lost revenue (Returned)
  ROUND(SUM(CASE WHEN o.status = 'Returned' THEN oi.sale_price ELSE 0 END)::numeric, 2) 
    as returned_revenue,
  -- Potential revenue still in pipeline
  ROUND(SUM(CASE WHEN o.status = 'Processing' THEN oi.sale_price ELSE 0 END)::numeric, 2) 
    as processing_revenue,
  -- Calculate leakage rate
  ROUND(100.0 * SUM(CASE WHEN o.status IN ('Cancelled', 'Returned') THEN oi.sale_price ELSE 0 END) / 
    NULLIF(SUM(oi.sale_price), 0), 2) as leakage_rate_pct,
  -- Total potential
  ROUND(SUM(oi.sale_price)::numeric, 2) as total_potential_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.created_at >= '2023-01-01'  -- Last 2 years
  AND o.created_at < '2025-01-01'
GROUP BY 1
ORDER BY 1 DESC;


WITH monthly_revenue AS (
  SELECT 
    DATE_TRUNC('month', oi.created_at) as month,
    COUNT(DISTINCT oi.order_id) as total_orders,
    COUNT(DISTINCT oi.id) as total_items,
    SUM(oi.sale_price) as total_revenue,
    AVG(oi.sale_price) as avg_item_price,
    COUNT(DISTINCT oi.user_id) as unique_customers
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')  -- Only revenue-generating orders
    AND oi.created_at >= '2019-01-01' 
    AND oi.created_at < '2025-01-01'  -- Exclude future dates
  GROUP BY 1
)
SELECT 
  month,
  total_orders,
  total_items,
  ROUND(total_revenue::numeric, 2) as total_revenue,
  ROUND(avg_item_price::numeric, 2) as avg_item_price,
  unique_customers,
  ROUND((total_revenue / total_orders)::numeric, 2) as avg_order_value,
  ROUND((total_items::numeric / total_orders), 2) as items_per_order,
  -- Month-over-month growth
  ROUND(100.0 * (total_revenue - LAG(total_revenue) OVER (ORDER BY month)) / 
    NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0), 2) as mom_revenue_growth_pct,
  ROUND(100.0 * (total_orders - LAG(total_orders) OVER (ORDER BY month)) / 
    NULLIF(LAG(total_orders) OVER (ORDER BY month), 0), 2) as mom_orders_growth_pct,
  -- Year-over-year growth
  ROUND(100.0 * (total_revenue - LAG(total_revenue, 12) OVER (ORDER BY month)) / 
    NULLIF(LAG(total_revenue, 12) OVER (ORDER BY month), 0), 2) as yoy_revenue_growth_pct
FROM monthly_revenue
ORDER BY month;

