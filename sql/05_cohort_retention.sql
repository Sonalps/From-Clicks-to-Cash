-- ============================================================================
-- FILE: 06_cohort_retention.sql (FINAL - GLOBAL ANALYSIS)
-- PURPOSE: WHEN do customers churn? What's the critical drop-off point?
-- CONTEXT: File 05 showed 29% repeat rate across ALL countries (universal problem)
-- GOAL: Identify WHEN to intervene with retention campaigns
-- ============================================================================

-- ----------------------------------------------------------------------------
-- COMPREHENSIVE COHORT RETENTION ANALYSIS
-- Shows Month-by-Month retention for cohorts (2023 cohorts for full 12-month view)
-- ----------------------------------------------------------------------------
WITH first_purchase AS (
  -- Identify each customer's first purchase (cohort assignment)
  SELECT 
    user_id,
    DATE_TRUNC('month', MIN(created_at)) as cohort_month,
    MIN(created_at) as first_purchase_date,
    -- Capture first order metrics
    MIN(EXTRACT(YEAR FROM created_at)) as first_purchase_year
  FROM orders
  WHERE status IN ('Complete', 'Shipped')
    AND created_at >= '2019-01-01' 
    AND created_at < '2025-01-01'
  GROUP BY user_id
),
cohort_size AS (
  -- Count how many customers in each cohort
  SELECT 
    fp.cohort_month,
    COUNT(DISTINCT fp.user_id) as cohort_size,
    -- Calculate average first order value
    ROUND(AVG(first_order_revenue.revenue)::numeric, 2) as avg_first_order_value
  FROM first_purchase fp
  LEFT JOIN (
    SELECT 
      o.user_id,
      SUM(oi.sale_price) as revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN first_purchase fp2 ON o.user_id = fp2.user_id
    WHERE o.status IN ('Complete', 'Shipped')
      AND DATE_TRUNC('month', o.created_at) = fp2.cohort_month
    GROUP BY o.user_id
  ) first_order_revenue ON fp.user_id = first_order_revenue.user_id
  GROUP BY fp.cohort_month
),
monthly_activity AS (
  -- Track which customers are active in which months after first purchase
  SELECT 
    fp.cohort_month,
    fp.user_id,
    DATE_TRUNC('month', o.created_at) as activity_month,
    EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.created_at), fp.cohort_month)) as months_since_first,
    COUNT(DISTINCT o.order_id) as orders_in_period,
    ROUND(SUM(oi.sale_price)::numeric, 2) as revenue_in_period
  FROM first_purchase fp
  JOIN orders o ON fp.user_id = o.user_id
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.status IN ('Complete', 'Shipped')
    AND o.created_at >= fp.first_purchase_date
  GROUP BY fp.cohort_month, fp.user_id, DATE_TRUNC('month', o.created_at)
),
cohort_metrics AS (
  -- Aggregate retention metrics by cohort and month
  SELECT 
    ma.cohort_month,
    cs.cohort_size as initial_customers,
    cs.avg_first_order_value,
    ma.months_since_first,
    
    -- Retention metrics
    COUNT(DISTINCT ma.user_id) as retained_customers,
    ROUND(100.0 * COUNT(DISTINCT ma.user_id) / cs.cohort_size, 2) as retention_rate_pct,
    
    -- Revenue metrics
    SUM(ma.orders_in_period) as total_orders_in_month,
    ROUND(SUM(ma.revenue_in_period)::numeric, 2) as total_revenue_in_month,
    ROUND(AVG(ma.revenue_in_period)::numeric, 2) as avg_revenue_per_retained_customer,
    
    -- Churn calculation
    ROUND(100.0 * (cs.cohort_size - COUNT(DISTINCT ma.user_id)) / cs.cohort_size, 2) as churn_rate_pct,
    
    -- Retention phase classification
    CASE 
      WHEN ma.months_since_first = 0 THEN 'Month 0 (Acquisition)'
      WHEN ma.months_since_first = 1 THEN 'Month 1 (Critical Period)'
      WHEN ma.months_since_first BETWEEN 2 AND 3 THEN 'Months 2-3 (Early Retention)'
      WHEN ma.months_since_first BETWEEN 4 AND 6 THEN 'Months 4-6 (Mid Retention)'
      ELSE 'Months 7-12 (Long-term Loyalty)'
    END as retention_phase
    
  FROM monthly_activity ma
  JOIN cohort_size cs ON ma.cohort_month = cs.cohort_month
  WHERE ma.months_since_first <= 12  -- First year only
  GROUP BY 
    ma.cohort_month, 
    cs.cohort_size, 
    cs.avg_first_order_value,
    ma.months_since_first
),
cumulative_metrics AS (
  -- Calculate cumulative LTV over time
  SELECT 
    *,
    ROUND(SUM(total_revenue_in_month) OVER (
      PARTITION BY cohort_month 
      ORDER BY months_since_first
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::numeric, 2) as cumulative_revenue,
    
    ROUND((SUM(total_revenue_in_month) OVER (
      PARTITION BY cohort_month 
      ORDER BY months_since_first
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) / initial_customers)::numeric, 2) as cumulative_ltv_per_customer
  FROM cohort_metrics
)
SELECT 
  cohort_month,
  initial_customers,
  avg_first_order_value,
  months_since_first,
  retention_phase,
  
  -- Retention metrics
  retained_customers,
  retention_rate_pct,
  churn_rate_pct,
  
  -- Revenue metrics
  total_orders_in_month,
  total_revenue_in_month,
  avg_revenue_per_retained_customer,
  
  -- Cumulative metrics
  cumulative_revenue,
  cumulative_ltv_per_customer,
  
  -- Month-over-month retention change (to spot drop-off points)
  retention_rate_pct - LAG(retention_rate_pct) OVER (
    PARTITION BY cohort_month 
    ORDER BY months_since_first
  ) as retention_change_from_prior_month,
  
  -- Benchmark indicator
  CASE 
    WHEN months_since_first = 1 AND retention_rate_pct < 30 THEN '🚨 Critical: <30% Month-1 retention'
    WHEN months_since_first = 3 AND retention_rate_pct < 20 THEN '⚠️ Warning: <20% Month-3 retention'
    WHEN months_since_first = 6 AND retention_rate_pct < 15 THEN '⚠️ Warning: <15% Month-6 retention'
    WHEN months_since_first = 12 AND retention_rate_pct >= 10 THEN '✅ Good: 10%+ Month-12 retention'
    WHEN months_since_first = 12 AND retention_rate_pct < 10 THEN '🔴 Poor: <10% Month-12 retention'
    ELSE NULL
  END as retention_benchmark
  
FROM cumulative_metrics
WHERE cohort_month >= '2023-01-01'  -- Recent cohorts with complete 12-month data
  AND cohort_month < '2024-01-01'  -- Only 2023 cohorts for full year view
ORDER BY 
  cohort_month DESC, 
  months_since_first;


-- ============================================================================
-- WHAT TO LOOK FOR IN RESULTS:
-- ============================================================================
-- 
-- KEY QUESTIONS:
-- 1. What % of customers return in Month 1? (Benchmark: 30%+)
-- 2. What's the biggest drop-off point? (Month 0→1? Month 1→2?)
-- 3. Does retention stabilize after Month 3? (Flattening curve)
-- 4. What's the cumulative LTV after 12 months? (Should be >$150)
-- 5. Which month shows the sharpest decline? (Critical intervention point)
--
-- EXPECTED FINDINGS (Based on 29% overall repeat rate):
-- - Month 0: 100% (by definition - first purchase)
-- - Month 1: ~20-25% (71% churn immediately after first purchase)
-- - Month 2: ~15-18% (another drop)
-- - Month 3: ~12-15% (stabilizing)
-- - Month 12: ~8-10% (long-term loyal customers)
--
-- CRITICAL INSIGHT TO FIND:
-- If Month 0→1 shows 75-80% drop (100% → 20-25%), this is WHERE to intervene.
-- Launch retention campaign on Day 7, 14, 30 after first purchase.
--
-- SHARE WITH ME:
-- 1. Retention rates for Months 0, 1, 2, 3, 6, 12
-- 2. The month with biggest retention drop
-- 3. Cumulative LTV at Month 12
-- 4. Any cohort with significantly different pattern
--
-- ============================================================================