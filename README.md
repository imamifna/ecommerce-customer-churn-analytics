# End-to-End E-Commerce Customer Churn Pipeline & Enterprise Data Mart

> **Business Value Impact:** Engineered a structured data pipeline using Medallion Architecture to isolate **$152.03K in Financial Revenue at Risk** caused by customer attrition, formulating data-driven retention strategies to mitigate a macro **16.84% Churn Rate**.

---

## 📌 Executive Summary (The 5-Second Pitch)
This project integrates raw e-commerce operational data into a modern relational database architecture to systematically solve customer attrition. Leveraging the **Single Source of Truth (SSOT)** framework, this pipeline transforms unstandardized `VARCHAR`-based staging data into an optimized *Analytical View Layer* (SQL). This layer is seamlessly consumed in real-time by a 3-Page Power BI Dashboard (*Executive Overview, Behavioral Analytics, & Lifecycle Risk*) without compromising DAX semantic model rendering performance.

* **Core Business Metrics:** Macro Churn Rate (16.84%), Total Revenue at Risk ($152.03K), New User Churn Rate (45.73%), Complain Rate (28.49%).
* **Data Volume Processed:** 5,630 Unique Customers & 948 Churned Lifecycle Records.
* **Tech Stack:** Advanced SQL (Type Casting, Dynamic View Engineering, Safe Division Handling), Power BI (Star Schema Modeling, Explicit DAX Semantic Layer).

---

## 🖥️ Dashboard Previews

### 1. Executive Churn Overview
![Executive Overview](dashboards/Executive%20Churn%20Overview.png)

### 2. Behavioral & Promo Analytics
![Behavioral Analytics](dashboards/Behavioral%20%26%20Promo%20Analytics.png)

### 3. Customer Cohort & Lifecycle Risk
![Cohort Risk](dashboards/Customer%20Cohort%20%26%20Lifecycle%20Risk.png)

---

## 📊 1. Situation & Context (S)
In high-velocity E-commerce ecosystems, acquiring a new customer (*Customer Acquisition Cost* / CAC) is up to 5x more expensive than retaining an existing one (*Customer Retention*). Executive stakeholders faced extreme visibility gaps regarding a macro churn rate of **16.84%**. Operational transaction logs and customer profiles were heavily fragmented across unstandardized formats (*dirty data*), riddled with structural nulls (*missing values*), and plagued by categorical input text inconsistencies. Without a reliable, clean data abstraction layer bridging the data warehouse and the presentation layer, the Growth Marketing team could not deploy tactical intervention frameworks to prevent accelerating revenue leakage.

## 🎯 2. Task & Objective (T)
As the Technical Data Analyst, I owned the data modeling architecture and the business analytics logic deployment on the presentation layer. My core technical and strategic objectives included:
1. **Data Infrastructure Segregation:** Isolating raw operational staging data (`raw_ecom`) from the analytical consumption environment (`analytics_gold`) using the Medallion Data Architecture framework.
2. **Data Preprocessing & Structural Realignment:** Conducting login device standardization, deploying safe data-type conversions, handling null values defensively, and engineering downstream business metrics (e.g., `promo_transaction_ratio`) via SQL.
3. **Executive Business Intelligence Delivery:** Engineering an interactive 3-page Power BI dashboard to isolate high-risk customer cohorts based on lifecycle duration (*Tenure*) and customer friction touchpoints (*Complaints*).

## 🛠️ 3. Action & Technical Implementation (A)

The data pipeline was systematically engineered across modular SQL execution layers:

### A. Raw Ingestion & Staging Layer (`sql_queries/01_raw_table_setup.sql`)
To completely mitigate ingestion pipeline failures triggered by empty strings or corrupted data types from the open-source Kaggle CSV file, all analytical metrics were ingested as raw `VARCHAR(50)` fields. This guaranteed data ingestion safety and decoupling.

### B. Analytical Gold View & Feature Engineering (`sql_queries/02_analytics_view_transform.sql`)
I constructed a highly performant *Dynamic View* (`dim_customer_churn_retention`) to execute computation-heavy preprocessing at the database layer, offloading compute strain from the BI engine memory:
* **Advanced Imputation & Null Value Handling:** Converted empty string values and structural nulls within high-stakes metrics (`Tenure`, `WarehouseToHome`, `DaySinceLastOrder`) into standard fallback analytical flags (`0` or `-1`) using robust conditional `CASE WHEN` statements.
* **Categorical String Standardization:** Fixed text redundancy anomalies by consolidating categorical values (e.g., merging `'Phone'` and `'Mobile Phone'` into a single standardized `'Mobile Phone'` string token) using `LOWER(TRIM())`.
* **Mathematical Feature Engineering:** Calculated customer promotion dependency elasticity using a zero-division protected database logic formula:

```sql
-- Promotion dependency metric formula used in production view execution
ROUND(
    CASE 
        WHEN coupons_used_count > 0 AND order_count_12m > 0 
            THEN CAST(coupons_used_count AS DECIMAL(10,2)) / CAST(order_count_12m AS DECIMAL(10,2))
        ELSE 0.0
    END, 2
) AS promo_transaction_ratio


+-------------------------------+-------------------+------------------+-----------------------+
|        Tenure Segment         |  Total Customers  | Churned Customers| Cohort Churn Rate (%) |
+-------------------------------+-------------------+------------------+-----------------------+
| 0. New User (<1 Month)        |        772        |        353       |        45.73%         |
| 1. Junior User (1-6 Months)   |       1642        |        425       |        25.88%         |
| 2. Mid-Loyal (7-12 Months)    |       1320        |         75       |         5.68%         |
| 3. Core Loyal (>1 Year)       |       1896        |         95       |         5.01%         |
+-------------------------------+-------------------+------------------+-----------------------+

📊 ecommerce-churn-analysis/
│
├── 📂 dashboards/
│   ├── Behavioral & Promo Analytics.png
│   ├── Customer Cohort & Lifecycle Risk.png
│   ├── ECommerce_Churn_Analytics_Dashboard.pbix
│   └── Executive Churn Overview.png
│
├── 📂 data/
│   ├── Columns_Description.csv
│   ├── cleaned_dataset.csv
│   ├── cleaned_dataset_sample.csv
│   └── raw_dataset.csv
│
├── 📂 sql_queries/
│   ├── 01_raw_table_setup.sql
│   ├── 02_analytics_view_transform.sql
│   └── 03_business_insights_query.sql
│
└── README.md
