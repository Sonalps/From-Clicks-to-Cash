-- ============================================================================
-- FILE: 05_geographic_analysis.sql (1 COMPREHENSIVE QUERY - FIXED)
-- ============================================================================

WITH country_metrics AS (
  SELECT 
    u.country,
    -- Volume metrics
    COUNT(DISTINCT o.user_id) as total_customers,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT oi.id) as total_items,
    
    -- Revenue metrics
    ROUND(SUM(oi.sale_price)::numeric, 2) as total_revenue,
    ROUND(AVG(oi.sale_price)::numeric, 2) as avg_item_price,
    ROUND((SUM(oi.sale_price) / COUNT(DISTINCT o.user_id))::numeric, 2) as customer_ltv,
    ROUND((SUM(oi.sale_price) / COUNT(DISTINCT o.order_id))::numeric, 2) as avg_order_value,
    
    -- Behavioral metrics
    ROUND((COUNT(DISTINCT o.order_id)::numeric / COUNT(DISTINCT o.user_id)), 2) as orders_per_customer,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN repeat_flag.order_count > 1 THEN o.user_id END) / 
      COUNT(DISTINCT o.user_id), 2) as repeat_rate_pct,
    
    -- Demographics
    ROUND(AVG(u.age)::numeric, 1) as avg_customer_age,
    MODE() WITHIN GROUP (ORDER BY u.gender) as dominant_gender,
    
    -- Product preferences
    MODE() WITHIN GROUP (ORDER BY p.category) as top_category,
    MODE() WITHIN GROUP (ORDER BY p.department) as top_department,
    
    -- Growth metrics (2024 vs 2023)
    ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM o.created_at) = 2024 THEN oi.sale_price ELSE 0 END)::numeric, 2) as revenue_2024,
    ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM o.created_at) = 2023 THEN oi.sale_price ELSE 0 END)::numeric, 2) as revenue_2023,
    COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM o.created_at) = 2024 THEN o.user_id END) as customers_2024,
    COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM o.created_at) = 2023 THEN o.user_id END) as customers_2023
    
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN users u ON o.user_id = u.id
  JOIN products p ON oi.product_id = p.id
  LEFT JOIN (
    SELECT user_id, COUNT(DISTINCT order_id) as order_count
    FROM orders
    WHERE status IN ('Complete', 'Shipped')
    GROUP BY user_id
  ) repeat_flag ON o.user_id = repeat_flag.user_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND o.created_at >= '2019-01-01' 
    AND o.created_at < '2025-01-01'
  GROUP BY u.country
),
country_with_growth AS (
  SELECT 
    *,
    -- Calculate growth rates
    ROUND(100.0 * (revenue_2024 - revenue_2023) / NULLIF(revenue_2023, 0), 2) as revenue_yoy_growth_pct,
    ROUND(100.0 * (customers_2024 - customers_2023) / NULLIF(customers_2023, 0), 2) as customer_yoy_growth_pct
  FROM country_metrics
)
SELECT 
  country,
  total_customers,
  total_orders,
  total_revenue,
  ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (), 2) as pct_of_total_revenue,
  customer_ltv,
  avg_order_value,
  avg_item_price,
  orders_per_customer,
  repeat_rate_pct,
  avg_customer_age,
  dominant_gender,
  top_category,
  top_department,
  revenue_yoy_growth_pct,
  customer_yoy_growth_pct,
  
  -- Strategic classification
  CASE 
    WHEN customer_ltv >= 100 AND repeat_rate_pct >= 35 THEN '⭐ Star Market (High LTV + High Loyalty)'
    WHEN customer_ltv >= 100 AND repeat_rate_pct < 35 THEN '💰 High Spend, Low Loyalty'
    WHEN customer_ltv < 100 AND repeat_rate_pct >= 35 THEN '🔄 Loyal but Low Spend'
    WHEN total_customers >= 1000 THEN '📈 Volume Market (Scale Opportunity)'
    ELSE '🌱 Emerging Market'
  END as market_type,
  
  -- Priority ranking for investment
  CASE 
    WHEN customer_ltv >= 100 AND repeat_rate_pct >= 35 AND revenue_yoy_growth_pct > 30 
      THEN 'Priority 1: Invest Heavy'
    WHEN customer_ltv >= 100 OR repeat_rate_pct >= 35 
      THEN 'Priority 2: Grow & Optimize'
    WHEN total_customers >= 500 
      THEN 'Priority 3: Test & Learn'
    ELSE 'Priority 4: Monitor'
  END as investment_priority

FROM country_with_growth
WHERE total_customers >= 100  -- Filter out tiny markets
ORDER BY total_revenue DESC;