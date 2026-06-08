-- ============================================================================
-- Pipeline Stage : 2. Transformation & Modeling (Analytics / Gold Layer)
-- File Name      : 02_analytics_view_transform.sql
-- Target Object  : analytics_gold.dim_customer_churn_retention (VIEW)
-- Description    : Transforms raw staging data (Bronze) into a clean Data Mart (Gold)
--                  using a Common Table Expression (CTE) architecture.
--                  Handles data cleansing, type casting, and embeds business logic
--                  such as the 60-day inactivity rule and Promo Hunter ratio.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS analytics_gold;
USE analytics_gold;

CREATE OR REPLACE VIEW dim_customer_churn_retention AS
WITH staging_cleaned AS (
    -- ------------------------------------------------------------------------
    -- STEP 1: Data Cleansing, Type Casting & Handling Missing Values (NULL)
    -- ------------------------------------------------------------------------
    SELECT
        CAST(CustomerID AS UNSIGNED)               AS customer_id,
        CAST(Churn AS UNSIGNED)                    AS raw_churn_flag,
        
        -- Handle empty cells in Tenure (Default: 0 months for New Users)
        CASE WHEN Tenure = '' OR Tenure IS NULL THEN 0 ELSE CAST(Tenure AS SIGNED) END AS tenure_months,
        
        -- Synchronize variations in login device naming conventions
        CASE 
            WHEN PreferredLoginDevice IN ('Phone', 'Mobile Phone') THEN 'Mobile Phone'
            WHEN PreferredLoginDevice = 'Computer' THEN 'Computer'
            ELSE COALESCE(PreferredLoginDevice, 'Unknown')
        END AS preferred_login_device,
        
        CAST(CityTier AS UNSIGNED)                 AS city_tier,
        
        -- Handle warehouse distance anomalies (Default: -1 for missing values)
        CASE WHEN WarehouseToHome = '' OR WarehouseToHome IS NULL THEN -1 ELSE CAST(WarehouseToHome AS SIGNED) END AS warehouse_to_home_km,
        
        -- Standardize payment method naming conventions
        CASE 
            WHEN PreferredPaymentMode = 'CC' THEN 'Credit Card'
            WHEN PreferredPaymentMode = 'COD' THEN 'Cash on Delivery'
            ELSE COALESCE(PreferredPaymentMode, 'Unknown')
        END AS preferred_payment_mode,
        
        LOWER(TRIM(Gender))                        AS gender,
        
        -- Handle app usage duration in the last 30 days
        CASE WHEN HourSpendOnApp = '' OR HourSpendOnApp IS NULL THEN 0 ELSE CAST(HourSpendOnApp AS SIGNED) END AS app_session_hours_30d,
        
        CAST(NumberOfDeviceRegistered AS UNSIGNED) AS registered_devices_count,
        
        -- Synchronize favorite product category variations
        CASE 
            WHEN PreferedOrderCat = 'Mobile' THEN 'Mobile Phone'
            ELSE COALESCE(PreferedOrderCat, 'Unknown')
        END AS preferred_order_category,
        
        CAST(SatisfactionScore AS UNSIGNED)        AS satisfaction_score,
        TRIM(MaritalStatus)                        AS marital_status,
        CAST(NumberOfAddress AS UNSIGNED)          AS address_count,
        CAST(Complain AS UNSIGNED)                 AS complain_status_30d,
        
        -- Format to Decimal for financial and percentage metrics
        CASE WHEN OrderAmountHikeFromlastYear = '' OR OrderAmountHikeFromlastYear IS NULL THEN 0.0 ELSE CAST(OrderAmountHikeFromlastYear AS DECIMAL(5,2)) END AS order_amount_hike_percent,
        CASE WHEN CouponUsed = '' OR CouponUsed IS NULL THEN 0 ELSE CAST(CouponUsed AS SIGNED) END AS coupons_used_count,
        CASE WHEN OrderCount = '' OR OrderCount IS NULL THEN 0 ELSE CAST(OrderCount AS SIGNED) END AS order_count_12m,
        
        -- Recency: Days since last order (Default: -1 if data is empty)
        CASE WHEN DaySinceLastOrder = '' OR DaySinceLastOrder IS NULL THEN -1 ELSE CAST(DaySinceLastOrder AS SIGNED) END AS recency_days,
        
        CASE WHEN CashbackAmount = '' OR CashbackAmount IS NULL THEN 0.00 ELSE CAST(CashbackAmount AS DECIMAL(10,2)) END AS total_monetary_cashback
    FROM raw_ecom.e_commerce_dataset
),

business_logic_applied AS (
    -- ------------------------------------------------------------------------
    -- STEP 2: Apply Business Rules & Feature Engineering Based on PO Request
    -- ------------------------------------------------------------------------
    SELECT
        *,
        -- 1. Churn Target Logic: Churn if historical flag is 1 OR inactive for >= 60 days
        CASE 
            WHEN raw_churn_flag = 1 OR recency_days >= 60 THEN 1 
            ELSE 0 
        END AS churn_target,
        
        -- 2. Promo Transaction Ratio Logic: Calculate discount dependency (Promo Hunter behavior)
        ROUND(
            CASE 
                WHEN coupons_used_count > 0 AND order_count_12m > 0 
                    THEN CAST(coupons_used_count AS DECIMAL(10,2)) / CAST(order_count_12m AS DECIMAL(10,2))
                ELSE 0.0
            END, 2
        ) AS promo_transaction_ratio,

        -- 3. Customer Tenure Segmentation for optimized slicing in Power BI
        CASE 
            WHEN tenure_months = 0 THEN '0. New User (<1 Month)'
            WHEN tenure_months BETWEEN 1 AND 6 THEN '1. Junior User (1-6 Months)'
            WHEN tenure_months BETWEEN 7 AND 12 THEN '2. Mid-Loyal (7-12 Months)'
            ELSE '3. Core Loyal (>1 Year)'
        END AS tenure_segment
    FROM staging_cleaned
)

-- ----------------------------------------------------------------------------
-- STEP 3: Final Selection & Delivery Layer
-- ----------------------------------------------------------------------------
SELECT
    customer_id,
    churn_target,
    tenure_months,
    tenure_segment,
    preferred_login_device,
    city_tier,
    warehouse_to_home_km,
    preferred_payment_mode,
    gender,
    app_session_hours_30d,
    registered_devices_count,
    preferred_order_category,
    satisfaction_score,
    marital_status,
    address_count,
    complain_status_30d,
    order_amount_hike_percent,
    coupons_used_count,
    order_count_12m,
    recency_days,
    total_monetary_cashback,
    promo_transaction_ratio,
    NOW() AS dw_inserted_at
FROM business_logic_applied;
