-- ============================================================================
-- Pipeline Stage : 3. Business Analytics & Insights Layer (Dashboard Alignment)
-- File Name      : 03_business_insights_query.sql
-- Target Source  : analytics_gold.dim_customer_churn_retention (VIEW)
-- Description    : Executes high-level business intelligence queries designed to
--                  generate executive insights. Strategically structured to 
--                  serve as the database-level single source of truth (SSOT),
--                  replicating complex Power BI DAX semantic model measures.
-- ============================================================================

USE analytics_gold;

-- ============================================================================
-- SECTION 1: EXECUTIVE BASELINE METRICS (Dashboard Core KPIs)
-- Objectives: Evaluate total portfolio size, active churn volume, overall 
--             churn exposure rate, and financial capital at risk.
-- ============================================================================
SELECT 
    COUNT(customer_id) AS total_customers,
    SUM(churn_target) AS churned_customers,
    ROUND((SUM(churn_target)/COUNT(customer_id))*100, 2) AS overall_churn_rate_percent,
    -- Financial Impact: Aggregates total cashback loss incurred from churned cohorts
    SUM(CASE WHEN churn_target = 1 THEN total_monetary_cashback ELSE 0.00 END) AS total_revenue_at_risk
FROM dim_customer_churn_retention;



-- ============================================================================
-- SECTION 2: BEHAVIORAL, FRICTION, & PROMO ANALYTICS (Operational Deep-Dive)
-- Objectives: Quantify correlation between customer friction (complaints),
--             discount affinity (Promo Hunters), and product engagement.
-- ============================================================================
SELECT 
    -- 1. Operational Friction (Customer Complaint Distribution)
    ROUND(AVG(complain_status_30d), 2) AS overall_complain_rate,
    
    -- [FIXED] Added CAST and NULLIF to ensure safe decimal division and eliminate syntax crashes
    ROUND(
        CAST(SUM(CASE WHEN complain_status_30d = 1 AND churn_target = 1 THEN 1 ELSE 0 END) AS DECIMAL(10,2)) / 
        NULLIF(CAST(SUM(CASE WHEN complain_status_30d = 1 THEN 1 ELSE 0 END) AS DECIMAL(10,2)), 0), 
        2
    ) AS churn_rate_from_complainers,
    
    -- 2. Promo & Voucher Elasticity (Discount Dependency Profiling)
    SUM(CASE WHEN promo_transaction_ratio > 0.30 THEN 1 ELSE 0 END) AS total_promo_hunter,
    
    -- Added CAST and NULLIF for robust calculation of promo hunter metrics
    ROUND(
        CAST(SUM(CASE WHEN promo_transaction_ratio > 0.30 AND churn_target = 1 THEN 1 ELSE 0 END) AS DECIMAL(10,2)) / 
        NULLIF(CAST(SUM(CASE WHEN promo_transaction_ratio > 0.30 THEN 1 ELSE 0 END) AS DECIMAL(10,2)), 0), 
        2
    ) AS promo_hunter_churn_rate,
    
    -- 3. Product Engagement Metric
    ROUND(AVG(app_session_hours_30d), 2) AS avg_app_session_hours
FROM dim_customer_churn_retention;


-- ============================================================================
-- SECTION 3: COHORT LIFECYCLE ANALYTICS (Retention Breakdown)
-- Objectives: Segment churn performance across specific user lifecycle 
--             milestones to identify high-risk tenure groups.
-- ============================================================================
SELECT 
    tenure_segment,
    COUNT(customer_id) AS total_customers,
    SUM(churn_target) AS total_churned,
    ROUND((SUM(churn_target)/COUNT(customer_id))*100, 2) AS cohort_churn_rate_percent
FROM dim_customer_churn_retention
WHERE tenure_segment IN ('0. New User (<1 Month)', '3. Core Loyal (>1 Year)')
GROUP BY tenure_segment
ORDER BY tenure_segment ASC;
