-- ============================================================================
-- FILE: 03_product_performance.sql (UPDATED AFTER REVENUE ANALYSIS)
-- PURPOSE: Deep-dive product and category analysis
-- KEY QUESTIONS FROM REVENUE ANALYSIS:
--   1. Why is AOV declining? (Product mix shift?)
--   2. Which categories drive growth vs drag it down?
--   3. Are we selling more low-price or high-price items?
--   4. What's the profitability picture? (Revenue vs Cost)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: Product Category Revenue Analysis (Comprehensive)
-- ----------------------------------------------------------------------------
WITH category_data AS (
  SELECT 
    p.category,
    p.department,
    SUM(oi.sale_price) as total_revenue,
    COUNT(DISTINCT oi.order_id) as total_orders,
    COUNT(DISTINCT p.id) as unique_products,
    COUNT(DISTINCT oi.user_id) as unique_customers,
    AVG(oi.sale_price) as avg_item_price,
    AVG(p.retail_price) as avg_retail_price,
    AVG(p.cost) as avg_product_cost,
    SUM(p.cost) as total_cost,
    -- Calculate for 2024 and 2023 separately for YoY growth
    SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2024 THEN oi.sale_price ELSE 0 END) as revenue_2024,
    SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2023 THEN oi.sale_price ELSE 0 END) as revenue_2023
  FROM order_items oi
  JOIN products p ON oi.product_id = p.id
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND oi.created_at >= '2019-01-01' 
    AND oi.created_at < '2025-01-01'
  GROUP BY p.category, p.department
)
SELECT 
  category,
  department,
  unique_products,
  total_orders,
  unique_customers,
  ROUND(total_revenue::numeric, 2) as total_revenue,
  ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (), 2) as pct_of_total_revenue,
  ROUND(avg_item_price::numeric, 2) as avg_item_price,
  ROUND(avg_retail_price::numeric, 2) as avg_retail_price,
  ROUND(avg_product_cost::numeric, 2) as avg_cost,
  ROUND(total_cost::numeric, 2) as total_cost,
  ROUND((total_revenue - total_cost)::numeric, 2) as gross_profit,
  ROUND(100.0 * (total_revenue - total_cost) / NULLIF(total_revenue, 0), 2) as gross_margin_pct,
  ROUND(100.0 * (revenue_2024 - revenue_2023) / NULLIF(revenue_2023, 0), 2) as yoy_growth_pct,
  -- Classify performance
  CASE 
    WHEN revenue_2024 > revenue_2023 * 1.5 THEN 'Star (Growing Fast)'
    WHEN revenue_2024 > revenue_2023 * 1.2 THEN 'Growing'
    WHEN revenue_2024 > revenue_2023 * 0.95 THEN 'Stable'
    ELSE 'Declining'
  END as performance_status
FROM category_data
ORDER BY total_revenue DESC;




-- ----------------------------------------------------------------------------
-- QUERY 2: Top 30 Products by Revenue (Best Sellers)
-- ----------------------------------------------------------------------------
SELECT 
  p.id AS product_id,
  p.name AS product_name,
  p.category,
  p.brand,
  COUNT(DISTINCT oi.order_id) AS times_purchased,
  COUNT(oi.id) AS units_sold,
  ROUND(SUM(oi.sale_price)::numeric, 2) AS total_revenue,
  ROUND(AVG(oi.sale_price)::numeric, 2) AS avg_sale_price,
  ROUND((p.retail_price - p.cost)::numeric, 2) AS margin_per_unit
FROM order_items oi
JOIN products p ON oi.product_id = p.id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('Complete', 'Shipped')
  AND oi.created_at >= '2019-01-01' 
  AND oi.created_at < '2025-01-01'
  AND oi.sale_price > 0
GROUP BY p.id, p.name, p.category, p.brand, p.retail_price, p.cost
ORDER BY total_revenue DESC
LIMIT 30;



-- ----------------------------------------------------------------------------
-- QUERY 3: Bottom 20 Products by Revenue (Potential Cuts)
-- ----------------------------------------------------------------------------
WITH product_performance AS (
  SELECT 
    p.name as product_name,
    p.category,
    p.department,
    p.brand,
    ROUND(p.retail_price::numeric, 2) as retail_price,
    COUNT(DISTINCT oi.order_id) as times_purchased,
    ROUND(SUM(oi.sale_price)::numeric, 2) as total_revenue,
    ROUND(AVG(oi.sale_price)::numeric, 2) as avg_sale_price,
    MAX(oi.created_at) as last_sold_date,
    EXTRACT(DAY FROM CURRENT_DATE - MAX(oi.created_at)) as days_since_last_sale
  FROM order_items oi
  JOIN products p ON oi.product_id = p.id
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND oi.created_at >= '2019-01-01' 
    AND oi.created_at < '2025-01-01'
  GROUP BY p.name, p.category, p.department, p.brand, p.retail_price
)
SELECT 
  product_name,
  category,
  department,
  retail_price,
  times_purchased,
  total_revenue,
  last_sold_date,
  days_since_last_sale,
  CASE 
    WHEN days_since_last_sale > 180 THEN 'Consider Removing (No sales 6+ months)'
    WHEN times_purchased < 5 THEN 'Low Demand'
    ELSE 'Monitor'
  END as recommendation
FROM product_performance
ORDER BY total_revenue ASC
LIMIT 20;



-- ----------------------------------------------------------------------------
-- QUERY 4: Department Performance Comparison
-- ----------------------------------------------------------------------------
SELECT 
  p.department,
  COUNT(DISTINCT p.id) as total_products,
  COUNT(DISTINCT p.category) as categories_count,
  COUNT(DISTINCT oi.order_id) as total_orders,
  COUNT(DISTINCT oi.user_id) as unique_customers,
  ROUND(SUM(oi.sale_price)::numeric, 2) as total_revenue,
  ROUND(100.0 * SUM(oi.sale_price) / SUM(SUM(oi.sale_price)) OVER (), 2) as pct_of_revenue,
  ROUND(AVG(oi.sale_price)::numeric, 2) as avg_item_price,
  ROUND(AVG(p.retail_price)::numeric, 2) as avg_retail_price,
  ROUND(AVG(p.cost)::numeric, 2) as avg_cost,
  ROUND((AVG(p.retail_price) - AVG(p.cost))::numeric, 2) as avg_margin,
  ROUND(100.0 * (AVG(p.retail_price) - AVG(p.cost)) / NULLIF(AVG(p.retail_price), 0), 2) as margin_pct,
  -- YoY Growth
  ROUND(100.0 * (
    SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2024 THEN oi.sale_price ELSE 0 END) -
    SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2023 THEN oi.sale_price ELSE 0 END)
  ) / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM oi.created_at) = 2023 THEN oi.sale_price ELSE 0 END), 0), 2) as yoy_growth_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('Complete', 'Shipped')
  AND oi.created_at >= '2019-01-01' 
  AND oi.created_at < '2025-01-01'
GROUP BY p.department
ORDER BY total_revenue DESC;


-- ----------------------------------------------------------------------------
-- QUERY 5: Price Tier Analysis (Understanding AOV Decline)
-- ----------------------------------------------------------------------------
WITH price_tiers AS (
  SELECT 
    oi.id,
    oi.sale_price,
    CASE 
      WHEN oi.sale_price < 20 THEN '1. Under $20 (Budget)'
      WHEN oi.sale_price < 50 THEN '2. $20-50 (Mid-Range)'
      WHEN oi.sale_price < 100 THEN '3. $50-100 (Premium)'
      WHEN oi.sale_price < 200 THEN '4. $100-200 (Luxury)'
      ELSE '5. $200+ (Ultra-Luxury)'
    END as price_tier,
    EXTRACT(YEAR FROM oi.created_at) as year
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND oi.created_at >= '2019-01-01' 
    AND oi.created_at < '2025-01-01'
)
SELECT 
  price_tier,
  COUNT(*) as items_sold,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_of_items,
  ROUND(SUM(sale_price)::numeric, 2) as total_revenue,
  ROUND(100.0 * SUM(sale_price) / SUM(SUM(sale_price)) OVER (), 2) as pct_of_revenue,
  ROUND(AVG(sale_price)::numeric, 2) as avg_price,
  -- Trend: 2019 vs 2024
  COUNT(CASE WHEN year = 2019 THEN 1 END) as items_2019,
  COUNT(CASE WHEN year = 2024 THEN 1 END) as items_2024,
  ROUND(100.0 * (
    COUNT(CASE WHEN year = 2024 THEN 1 END) - COUNT(CASE WHEN year = 2019 THEN 1 END)
  ) / NULLIF(COUNT(CASE WHEN year = 2019 THEN 1 END)::numeric, 0), 2) as growth_pct
FROM price_tiers
GROUP BY price_tier
ORDER BY price_tier;
-- ----------------------------------------------------------------------------
-- QUERY 5: Price Tier Analysis (Understanding AOV Decline)
-- ----------------------------------------------------------------------------
WITH price_tiers AS (
  SELECT 
    oi.sale_price,
    CASE 
      WHEN oi.sale_price < 20 THEN '1. Under $20'
      WHEN oi.sale_price < 50 THEN '2. $20-50'
      WHEN oi.sale_price < 100 THEN '3. $50-100'
      WHEN oi.sale_price < 200 THEN '4. $100-200'
      ELSE '5. $200+'
    END AS price_tier
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND oi.created_at >= '2019-01-01' 
    AND oi.created_at < '2025-01-01'
    AND oi.sale_price > 0
)
SELECT 
  price_tier,
  COUNT(*) AS items_sold,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_items,
  ROUND(SUM(sale_price)::numeric, 2) AS total_revenue,
  ROUND(100.0 * SUM(sale_price) / SUM(SUM(sale_price)) OVER (), 2) AS pct_of_revenue
FROM price_tiers
GROUP BY price_tier
ORDER BY price_tier;

-- ----------------------------------------------------------------------------
-- QUERY 6: Monthly Category Trends (Last 12 Months - Detect Shifts)
-- ----------------------------------------------------------------------------
SELECT 
  DATE_TRUNC('month', oi.created_at) as month,
  p.category,
  COUNT(DISTINCT oi.order_id) as orders,
  ROUND(SUM(oi.sale_price)::numeric, 2) as revenue,
  ROUND(AVG(oi.sale_price)::numeric, 2) as avg_item_price,
  ROUND(100.0 * SUM(oi.sale_price) / SUM(SUM(oi.sale_price)) OVER (PARTITION BY DATE_TRUNC('month', oi.created_at)), 2) as pct_of_month_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('Complete', 'Shipped')
  AND oi.created_at >= '2024-01-01'  -- Last 12 months
  AND oi.created_at < '2025-01-01'
GROUP BY 1, 2
ORDER BY 1 DESC, 4 DESC;


-- ----------------------------------------------------------------------------
-- QUERY 7: Brand Performance Analysis
-- ----------------------------------------------------------------------------
SELECT 
  COALESCE(p.brand, 'Unknown') as brand,
  COUNT(DISTINCT p.id) as products_count,
  COUNT(DISTINCT p.category) as categories,
  COUNT(DISTINCT oi.order_id) as orders,
  ROUND(SUM(oi.sale_price)::numeric, 2) as total_revenue,
  ROUND(100.0 * SUM(oi.sale_price) / SUM(SUM(oi.sale_price)) OVER (), 2) as pct_of_revenue,
  ROUND(AVG(oi.sale_price)::numeric, 2) as avg_item_price,
  ROUND(AVG(p.retail_price)::numeric, 2) as avg_retail_price,
  -- Margin analysis
  ROUND(AVG(p.cost)::numeric, 2) as avg_cost,
  ROUND((AVG(p.retail_price) - AVG(p.cost))::numeric, 2) as avg_margin,
  ROUND(100.0 * (AVG(p.retail_price) - AVG(p.cost)) / NULLIF(AVG(p.retail_price), 0), 2) as margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('Complete', 'Shipped')
  AND oi.created_at >= '2019-01-01' 
  AND oi.created_at < '2025-01-01'
GROUP BY 1
HAVING SUM(oi.sale_price) > 10000  -- Only brands with >$10K revenue
ORDER BY total_revenue DESC;

SELECT 
  COALESCE(p.brand, 'Unknown') AS brand,
  ROUND(SUM(oi.sale_price)::numeric, 2) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('Complete', 'Shipped')
  AND oi.created_at >= '2019-01-01' 
  AND oi.created_at < '2025-01-01'
GROUP BY 1
HAVING SUM(oi.sale_price) > 10000
ORDER BY total_revenue DESC
LIMIT 15;

-- ----------------------------------------------------------------------------
-- QUERY 8: Product Velocity (Fast Movers vs Slow Movers)
-- ----------------------------------------------------------------------------
WITH product_velocity AS (
  SELECT 
    p.id,
    p.name,
    p.category,
    p.department,
    p.retail_price,
    COUNT(DISTINCT oi.order_id) as times_purchased,
    ROUND(SUM(oi.sale_price)::numeric, 2) as total_revenue,
    MIN(oi.created_at) as first_sale_date,
    MAX(oi.created_at) as last_sale_date,
    EXTRACT(DAY FROM MAX(oi.created_at) - MIN(oi.created_at)) as selling_period_days,
    ROUND(COUNT(DISTINCT oi.order_id)::numeric / 
      NULLIF(EXTRACT(DAY FROM MAX(oi.created_at) - MIN(oi.created_at)), 0), 2) as avg_orders_per_day
  FROM order_items oi
  JOIN products p ON oi.product_id = p.id
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND oi.created_at >= '2023-01-01'  -- Last 2 years
    AND oi.created_at < '2025-01-01'
  GROUP BY p.id, p.name, p.category, p.department, p.retail_price
)
SELECT 
  name,
  category,
  department,
  retail_price,
  times_purchased,
  total_revenue,
  selling_period_days,
  avg_orders_per_day,
  CASE 
    WHEN avg_orders_per_day >= 1 THEN 'Fast Mover (1+ orders/day)'
    WHEN avg_orders_per_day >= 0.5 THEN 'Good Velocity (0.5-1 orders/day)'
    WHEN avg_orders_per_day >= 0.1 THEN 'Moderate (0.1-0.5 orders/day)'
    ELSE 'Slow Mover (<0.1 orders/day)'
  END as velocity_category
FROM product_velocity
WHERE selling_period_days > 30  -- Only products on sale for 30+ days
ORDER BY avg_orders_per_day DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- QUERY 9: Profitability Matrix (Revenue vs Margin)
-- ----------------------------------------------------------------------------
WITH category_profitability AS (
  SELECT 
    p.category,
    ROUND(SUM(oi.sale_price)::numeric, 2) as revenue,
    ROUND(SUM(p.cost * 1)::numeric, 2) as total_cost,  -- Approximation: 1 item per line
    ROUND((SUM(oi.sale_price) - SUM(p.cost * 1))::numeric, 2) as gross_profit,
    ROUND(100.0 * (SUM(oi.sale_price) - SUM(p.cost * 1)) / NULLIF(SUM(oi.sale_price), 0), 2) as margin_pct,
    ROUND(AVG(p.retail_price)::numeric, 2) as avg_price,
    -- Classify into quadrants
    CASE 
      WHEN SUM(oi.sale_price) > (SELECT AVG(cat_rev) FROM (
        SELECT SUM(oi2.sale_price) as cat_rev 
        FROM order_items oi2 
        JOIN products p2 ON oi2.product_id = p2.id 
        JOIN orders o2 ON oi2.order_id = o2.order_id
        WHERE o2.status IN ('Complete', 'Shipped')
        GROUP BY p2.category
      ) x) THEN 'High Revenue'
      ELSE 'Low Revenue'
    END as revenue_tier,
    CASE 
      WHEN 100.0 * (SUM(oi.sale_price) - SUM(p.cost * 1)) / NULLIF(SUM(oi.sale_price), 0) > 50
      THEN 'High Margin'
      ELSE 'Low Margin'
    END as margin_tier
  FROM order_items oi
  JOIN products p ON oi.product_id = p.id
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND oi.created_at >= '2019-01-01' 
    AND oi.created_at < '2025-01-01'
  GROUP BY p.category
)
SELECT 
  category,
  revenue,
  gross_profit,
  margin_pct,
  avg_price,
  revenue_tier,
  margin_tier,
  CASE 
    WHEN revenue_tier = 'High Revenue' AND margin_tier = 'High Margin' THEN ' Star (High Rev, High Margin)'
    WHEN revenue_tier = 'High Revenue' AND margin_tier = 'Low Margin' THEN ' Cash Cow (High Rev, Low Margin)'
    WHEN revenue_tier = 'Low Revenue' AND margin_tier = 'High Margin' THEN 'Niche (Low Rev, High Margin)'
    ELSE 'Problem (Low Rev, Low Margin)'
  END as strategic_position
FROM category_profitability
ORDER BY revenue DESC;


-- ----------------------------------------------------------------------------
-- QUERY 10: Cross-Category Purchase Analysis (Basket Analysis)
-- ----------------------------------------------------------------------------
WITH order_categories AS (
  SELECT 
    o.order_id,
    COUNT(DISTINCT p.category) as category_count,
    ROUND(SUM(oi.sale_price)::numeric, 2) as order_value
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN products p ON oi.product_id = p.id
  WHERE o.status IN ('Complete', 'Shipped')
    AND o.created_at >= '2019-01-01' 
    AND o.created_at < '2025-01-01'
  GROUP BY o.order_id
)
SELECT 
  CASE 
    WHEN category_count = 1 THEN '1 Category (Single-Category Order)'
    WHEN category_count = 2 THEN '2 Categories (Cross-Purchase)'
    WHEN category_count >= 3 THEN '3+ Categories (High Cross-Sell)'
  END as purchase_pattern,
  COUNT(*) as order_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_of_orders,
  ROUND(AVG(order_value)::numeric, 2) as avg_order_value,
  ROUND(SUM(order_value)::numeric, 2) as total_revenue,
  ROUND(100.0 * SUM(order_value) / SUM(SUM(order_value)) OVER (), 2) as pct_of_revenue
FROM order_categories
GROUP BY 
  CASE 
    WHEN category_count = 1 THEN '1 Category (Single-Category Order)'
    WHEN category_count = 2 THEN '2 Categories (Cross-Purchase)'
    WHEN category_count >= 3 THEN '3+ Categories (High Cross-Sell)'
  END
ORDER BY avg_order_value DESC;



