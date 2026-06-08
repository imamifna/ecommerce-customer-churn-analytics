-- ============================================================================
-- Pipeline Stage : 2. Data Transformation & Modeling (Analytics / Gold Layer)
-- File Name      : 02_analytics_view_transform.sql
-- Target Object  : analytics_gold.dim_customer_churn_retention (VIEW)
-- Description    : Transforms raw staging data from the operational database (raw_ecom)
--                  into a structured, high-performance Data Mart (analytics_gold).
-- ============================================================================

USE analytics_gold;

DROP VIEW IF EXISTS analytics_gold.dim_customer_churn_retention;

CREATE OR REPLACE VIEW dim_customer_churn_retention AS
SELECT
    customer_id,
    CASE 
        WHEN raw_churn_flag = 1 OR recency_days >= 60 THEN 1 
        ELSE 0 
    END AS churn_target,
    tenure_months,
    CASE 
        WHEN tenure_months = 0 THEN '0. New User (<1 Month)'
        WHEN tenure_months BETWEEN 1 AND 6 THEN '1. Junior User (1-6 Months)'
        WHEN tenure_months BETWEEN 7 AND 12 THEN '2. Mid-Loyal (7-12 Months)'
        ELSE '3. Core Loyal (>1 Year)'
    END AS tenure_segment,
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
    ROUND(
        CASE 
            WHEN coupons_used_count > 0 AND order_count_12m > 0 
                THEN CAST(coupons_used_count AS DECIMAL(10,2)) / CAST(order_count_12m AS DECIMAL(10,2))
            ELSE 0.0
        END, 2
    ) AS promo_transaction_ratio,
    NOW() AS dw_inserted_at
FROM (
    SELECT
        CAST(CustomerID AS UNSIGNED)               AS customer_id,
        CAST(Churn AS UNSIGNED)                    AS raw_churn_flag,
        CASE WHEN Tenure = '' OR Tenure IS NULL THEN 0 ELSE CAST(Tenure AS SIGNED) END AS tenure_months,
        CASE 
            WHEN PreferredLoginDevice IN ('Phone', 'Mobile Phone') THEN 'Mobile Phone'
            WHEN PreferredLoginDevice = 'Computer' THEN 'Computer'
            ELSE COALESCE(PreferredLoginDevice, 'Unknown')
        END AS preferred_login_device,
        CAST(CityTier AS UNSIGNED)                 AS city_tier,
        CASE WHEN WarehouseToHome = '' OR WarehouseToHome IS NULL THEN -1 ELSE CAST(WarehouseToHome AS SIGNED) END AS warehouse_to_home_km,
        CASE 
            WHEN PreferredPaymentMode = 'CC' THEN 'Credit Card'
            WHEN PreferredPaymentMode = 'COD' THEN 'Cash on Delivery'
            ELSE COALESCE(PreferredPaymentMode, 'Unknown')
        END AS preferred_payment_mode,
        LOWER(TRIM(Gender))                        AS gender,
        CASE WHEN HourSpendOnApp = '' OR HourSpendOnApp IS NULL THEN 0 ELSE CAST(HourSpendOnApp AS SIGNED) END AS app_session_hours_30d,
        CAST(NumberOfDeviceRegistered AS UNSIGNED) AS registered_devices_count,
        CASE 
            WHEN PreferedOrderCat = 'Mobile' THEN 'Mobile Phone'
            ELSE COALESCE(PreferedOrderCat, 'Unknown')
        END AS preferred_order_category,
        CAST(SatisfactionScore AS UNSIGNED)        AS satisfaction_score,
        TRIM(MaritalStatus)                        AS marital_status,
        CAST(NumberOfAddress AS UNSIGNED)          AS address_count,
        CAST(Complain AS UNSIGNED)                 AS complain_status_30d,
        CASE WHEN OrderAmountHikeFromlastYear = '' OR OrderAmountHikeFromlastYear IS NULL THEN 0.0 ELSE CAST(OrderAmountHikeFromlastYear AS DECIMAL(5,2)) END AS order_amount_hike_percent,
        CASE WHEN CouponUsed = '' OR CouponUsed IS NULL THEN 0 ELSE CAST(CouponUsed AS SIGNED) END AS coupons_used_count,
        CASE WHEN OrderCount = '' OR OrderCount IS NULL THEN 0 ELSE CAST(OrderCount AS SIGNED) END AS order_count_12m,
        CASE WHEN DaySinceLastOrder = '' OR DaySinceLastOrder IS NULL THEN -1 ELSE CAST(DaySinceLastOrder AS SIGNED) END AS recency_days,
        CASE WHEN CashbackAmount = '' OR CashbackAmount IS NULL THEN 0.00 ELSE CAST(CashbackAmount AS DECIMAL(10,2)) END AS total_monetary_cashback
    FROM raw_ecom.e_commerce_dataset
) AS base_cleaned_data;
