-- Check total records and date range for each table
SELECT 
  'orders' as table_name,
  COUNT(*) as total_records,
  MIN(created_at) as earliest_date,
  MAX(created_at) as latest_date,
  COUNT(DISTINCT user_id) as unique_users
FROM orders

UNION ALL

SELECT 
  'order_items',
  COUNT(*),
  MIN(created_at),
  MAX(created_at),
  COUNT(DISTINCT user_id)
FROM order_items

UNION ALL

SELECT 
  'users',
  COUNT(*),
  MIN(created_at),
  MAX(created_at),
  COUNT(DISTINCT id)
FROM users

UNION ALL

SELECT 
  'products',
  COUNT(*),
  NULL,
  NULL,
  COUNT(DISTINCT id)
FROM products;

-- Identify null values in critical fields
SELECT 
  COUNT(*) as total_orders,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as null_user_id,
  COUNT(CASE WHEN created_at IS NULL THEN 1 END) as null_created_at,
  COUNT(CASE WHEN status IS NULL THEN 1 END) as null_status,
  ROUND(100.0 * COUNT(CASE WHEN user_id IS NULL THEN 1 END) / COUNT(*), 2) as pct_null_user
FROM orders;

-- Check order status distribution
SELECT 
  status,
  COUNT(*) as order_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- Check for duplicate order IDs
SELECT 
  order_id,
  COUNT(*) as occurrence_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

--  CHECK NULL VALUES IN ORDER_ITEMS
SELECT 
  'order_items' as table_name,
  COUNT(*) as total_records,
  COUNT(CASE WHEN id IS NULL THEN 1 END) as null_id,
  COUNT(CASE WHEN order_id IS NULL THEN 1 END) as null_order_id,
  COUNT(CASE WHEN product_id IS NULL THEN 1 END) as null_product_id,
  COUNT(CASE WHEN sale_price IS NULL THEN 1 END) as null_sale_price,
  COUNT(CASE WHEN status IS NULL THEN 1 END) as null_status,
  ROUND(100.0 * COUNT(CASE WHEN sale_price IS NULL THEN 1 END) / COUNT(*), 2) as pct_null_price
FROM order_items;

-- 3. CHECK NULL VALUES IN USERS
SELECT 
  'users' AS table_name,
  COUNT(*) AS total_records,
  COUNT(CASE WHEN id IS NULL OR id::text = 'null' THEN 1 END) AS null_id,
  COUNT(CASE WHEN first_name IS NULL OR first_name = 'null' THEN 1 END) AS null_first_name,
  COUNT(CASE WHEN last_name IS NULL OR last_name = 'null' THEN 1 END) AS null_last_name,
  COUNT(CASE WHEN email IS NULL OR email = 'null' THEN 1 END) AS null_email,
  COUNT(CASE WHEN age IS NULL THEN 1 END) AS null_age,
  COUNT(CASE WHEN gender IS NULL OR gender = 'null' THEN 1 END) AS null_gender,
  COUNT(CASE WHEN state IS NULL OR state = 'null' THEN 1 END) AS null_state,
  COUNT(CASE WHEN street_address IS NULL OR street_address = 'null' THEN 1 END) AS null_street_address,
  COUNT(CASE WHEN postal_code IS NULL OR postal_code = 'null' THEN 1 END) AS null_postal_code,
  COUNT(CASE WHEN city IS NULL OR city = 'null' THEN 1 END) AS null_city,
  COUNT(CASE WHEN country IS NULL OR country = 'null' THEN 1 END) AS null_country,
  COUNT(CASE WHEN latitude IS NULL THEN 1 END) AS null_latitude,
  COUNT(CASE WHEN longitude IS NULL THEN 1 END) AS null_longitude,
  COUNT(CASE WHEN traffic_source IS NULL OR traffic_source = 'null' THEN 1 END) AS null_traffic_source,
  COUNT(CASE WHEN created_at IS NULL THEN 1 END) AS null_created_at,
  COUNT(CASE WHEN user_geom IS NULL THEN 1 END) AS null_user_geom,
  -- Percentage calculations for key fields
  ROUND(100.0 * COUNT(CASE WHEN country IS NULL OR country = 'null' THEN 1 END) / COUNT(*), 2) AS pct_null_country,
  ROUND(100.0 * COUNT(CASE WHEN email IS NULL OR email = 'null' THEN 1 END) / COUNT(*), 2) AS pct_null_email,
  ROUND(100.0 * COUNT(CASE WHEN age IS NULL THEN 1 END) / COUNT(*), 2) AS pct_null_age
FROM users;


SELECT 
  'products' AS table_name,
  COUNT(*) AS total_records,
  COUNT(CASE WHEN id IS NULL THEN 1 END) AS null_id,
  COUNT(CASE WHEN cost IS NULL THEN 1 END) AS null_cost,
  COUNT(CASE WHEN category IS NULL OR category = 'null' THEN 1 END) AS null_category,
  COUNT(CASE WHEN name IS NULL OR name = 'null' THEN 1 END) AS null_name,
  COUNT(CASE WHEN brand IS NULL OR brand = 'null' THEN 1 END) AS null_brand,
  COUNT(CASE WHEN retail_price IS NULL THEN 1 END) AS null_retail_price,
  COUNT(CASE WHEN department IS NULL OR department = 'null' THEN 1 END) AS null_department,
  COUNT(CASE WHEN sku IS NULL OR sku = 'null' THEN 1 END) AS null_sku,
  COUNT(CASE WHEN distribution_center_id IS NULL THEN 1 END) AS null_distribution_center_id,
  -- Percentage calculations for key fields
  ROUND(100.0 * COUNT(CASE WHEN category IS NULL OR category = 'null' THEN 1 END) / COUNT(*), 2) AS pct_null_category,
  ROUND(100.0 * COUNT(CASE WHEN brand IS NULL OR brand = 'null' THEN 1 END) / COUNT(*), 2) AS pct_null_brand,
  ROUND(100.0 * COUNT(CASE WHEN name IS NULL OR name = 'null' THEN 1 END) / COUNT(*), 2) AS pct_null_name,
  ROUND(100.0 * COUNT(CASE WHEN cost IS NULL THEN 1 END) / COUNT(*), 2) AS pct_null_cost,
  ROUND(100.0 * COUNT(CASE WHEN retail_price IS NULL THEN 1 END) / COUNT(*), 2) AS pct_null_retail_price
FROM products;

-- CHECK FOR DUPLICATES IN ALL TABLES
SELECT 
  'orders' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT order_id) as unique_ids,
  COUNT(*) - COUNT(DISTINCT order_id) as duplicates
FROM orders
UNION ALL
SELECT 
  'order_items',
  COUNT(*),
  COUNT(DISTINCT id),
  COUNT(*) - COUNT(DISTINCT id)
FROM order_items
UNION ALL
SELECT 
  'users',
  COUNT(*),
  COUNT(DISTINCT id),
  COUNT(*) - COUNT(DISTINCT id)
FROM users
UNION ALL
SELECT 
  'products',
  COUNT(*),
  COUNT(DISTINCT id),
  COUNT(*) - COUNT(DISTINCT id)
FROM products;

--  CHECK ORDER_ITEMS STATUS DISTRIBUTION
SELECT 
  status,
  COUNT(*) as item_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM order_items
GROUP BY status
ORDER BY item_count DESC;

-- CHECK DATE RANGES FOR ALL TABLES
SELECT 
  'orders' AS table_name,
  MIN(created_at) AS earliest_date,
  MAX(created_at) AS latest_date,
  MAX(created_at)::date - MIN(created_at)::date AS days_span
FROM orders
UNION ALL
SELECT 
  'order_items',
  MIN(created_at),
  MAX(created_at),
  MAX(created_at)::date - MIN(created_at)::date
FROM order_items
UNION ALL
SELECT 
  'users',
  MIN(created_at),
  MAX(created_at),
  MAX(created_at)::date - MIN(created_at)::date
FROM users;


-- 10. CHECK PRICE ANOMALIES
SELECT 
  'sale_price_stats' as metric,
  MIN(sale_price) as min_price,
  MAX(sale_price) as max_price,
  ROUND(AVG(sale_price)::numeric, 2) as avg_price,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sale_price)::numeric, 2) as median_price,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY sale_price)::numeric, 2) as p99_price
FROM order_items;


SELECT 
  COUNT(*) AS total_orders,
  COUNT(CASE WHEN returned_at IS NULL THEN 1 END) AS null_returned_at,
  COUNT(CASE WHEN shipped_at IS NULL THEN 1 END) AS null_shipped_at,
  COUNT(CASE WHEN delivered_at IS NULL THEN 1 END) AS null_delivered_at,
  COUNT(CASE WHEN num_of_item IS NULL THEN 1 END) AS null_num_of_item,
  -- Percentage calculations for key fields
  ROUND(100.0 * COUNT(CASE WHEN returned_at IS NULL THEN 1 END) / COUNT(*), 2) AS pct_null_returned_at,
  ROUND(100.0 * COUNT(CASE WHEN shipped_at IS NULL THEN 1 END) / COUNT(*), 2) AS pct_null_shipped_at,
  ROUND(100.0 * COUNT(CASE WHEN delivered_at IS NULL THEN 1 END) / COUNT(*), 2) AS pct_null_delivered_at
FROM orders;

-- 9. CHECK REFERENTIAL INTEGRITY
-- Do all order_items have valid order_ids?
SELECT 
  COUNT(*) as total_order_items,
  COUNT(DISTINCT oi.order_id) as unique_orders_in_items,
  (SELECT COUNT(DISTINCT order_id) FROM orders) as unique_orders_in_orders,
  COUNT(*) - (SELECT COUNT(*) FROM order_items oi 
              WHERE EXISTS (SELECT 1 FROM orders o WHERE o.order_id = oi.order_id)) 
    as orphaned_items
FROM order_items oi;