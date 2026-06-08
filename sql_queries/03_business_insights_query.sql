-- ============================================================================
-- Pipeline Stage : 3. Business Analytics & Insights Layer (Dashboard Alignment)
-- File Name      : 03_business_insights_query.sql
-- Target Source  : analytics_gold.dim_customer_churn_retention (VIEW)
-- Description    : Specialized SQL queries aligned with Power BI DAX measures.
--                  Provides a single source of truth for C-level executives.
-- ============================================================================

USE analytics_gold;

-- ============================================================================
-- SECTION 1: EXECUTIVE BASELINE METRICS (Dashboard Page 1)
-- Goals: Calculate Total Customers, Churned, Churn Rate, and Revenue at Risk.
-- ============================================================================
SELECT 
    COUNT(customer_id) AS total_customers,
    SUM(churn_target) AS churned_customers,
    ROUND((SUM(churn_target) / COUNT(customer_id)) * 100, 2) AS overall_churn_rate_percent,
    -- Revenue at Risk: Total cashback given to users who eventually churned
    SUM(CASE WHEN churn_target = 1 THEN total_monetary_cashback ELSE 0 END) AS total_revenue_at_risk
FROM dim_customer_churn_retention;


-- ============================================================================
-- SECTION 2: BEHAVIORAL, FRICTION, & PROMO ANALYTICS (Dashboard Page 2)
-- Goals: Analyze complaint correlation, App engagement, and Promo Hunter behaviors.
-- ============================================================================
SELECT 
    -- 1. Behavioral Friction (Complaints)
    ROUND(AVG(complain_status_30d), 2) AS overall_complain_rate,
    ROUND(
        (SUM(CASE WHEN complain_status_30d = 1 AND churn_target = 1 THEN 1 ELSE 0 END) / 
         SUM(CASE WHEN complain_status_30d = 1 THEN 1 ELSE 0 END)), 2
    ) AS churn_rate_from_complainers,
    
    -- 2. Promo & Coupon Engagement
    SUM(CASE WHEN promo_transaction_ratio > 0.30 THEN 1 ELSE 0 END) AS total_promo_hunter,
    ROUND(
        (SUM(CASE WHEN promo_transaction_ratio > 0.30 AND churn_target = 1 THEN 1 ELSE 0 END) / 
         SUM(CASE WHEN promo_transaction_ratio > 0.30 THEN 1 ELSE 0 END)), 2
    ) AS promo_hunter_churn_rate,
    
    -- 3. App Engagement
    ROUND(AVG(app_session_hours_30d), 2) AS avg_app_session_hours
FROM dim_customer_churn_retention;


-- ============================================================================
-- SECTION 3: COHORT LIFECYCLE ANALYTICS (Dashboard Page 3)
-- Goals: Drill down into Churn Rates based on customer lifecycle segments.
-- ============================================================================
SELECT 
    tenure_segment,
    COUNT(customer_id) AS total_customers,
    SUM(churn_target) AS total_churned,
    ROUND((SUM(churn_target) / COUNT(customer_id)) * 100, 2) AS cohort_churn_rate_percent
FROM dim_customer_churn_retention
WHERE tenure_segment IN ('0. New User (<1 Month)', '3. Core Loyal (>1 Year)')
GROUP BY tenure_segment
ORDER BY tenure_segment ASC;
