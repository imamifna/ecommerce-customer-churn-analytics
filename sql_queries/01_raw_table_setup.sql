-- ============================================================================
-- Pipeline Stage : 1. Ingestion (Raw / Bronze Layer)
-- File Name      : 01_raw_table_setup.sql
-- Description    : Creates the database schema and staging table for raw data.
--                  Uses loose data types (VARCHAR) to prevent ingestion failures
--                  caused by anomalies, empty strings, or untrimmed spaces in the source CSV.
-- Target Table   : raw_ecom.e_commerce_dataset (PHYSICAL TABLE)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS raw_ecom;
USE raw_ecom;

CREATE TABLE IF NOT EXISTS e_commerce_dataset (
    CustomerID INT PRIMARY KEY,
    Churn INT,
    Tenure VARCHAR(50),
    PreferredLoginDevice VARCHAR(100),
    CityTier INT,
    WarehouseToHome VARCHAR(50),
    PreferredPaymentMode VARCHAR(100),
    Gender VARCHAR(50),
    HourSpendOnApp VARCHAR(50),
    NumberOfDeviceRegistered INT,
    PreferedOrderCat VARCHAR(100),
    SatisfactionScore INT,
    MaritalStatus VARCHAR(100),
    NumberOfAddress INT,
    Complain INT,
    OrderAmountHikeFromlastYear VARCHAR(50),
    CouponUsed VARCHAR(50),
    OrderCount VARCHAR(50),
    DaySinceLastOrder VARCHAR(50),
    CashbackAmount VARCHAR(50)
);
