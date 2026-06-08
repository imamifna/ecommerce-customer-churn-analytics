# E-Commerce Customer Churn & Retention Analytics

> **Business Impact:** Identified and localized **$152.03K Revenue at Risk** and designed data-driven retention strategies through an end-to-end data pipeline (SQL to Power BI).

---

## 🚀 Executive Summary (The 5-Second Hook)
This project integrates industry-scale data preprocessing using **Medallion Architecture** in MySQL and an interactive **3-Page Power BI Dashboard** to mitigate a critical customer retention crisis. The analytics pipeline successfully captured a macro churn rate of **16.84%** (948 churned customers) and uncovered a critical business anomaly: customers with perfect satisfaction scores (Score 5) exhibit a massive surge in churn (*The Silent Killer*). Furthermore, it localized the highest financial vulnerability within **Junior Users (1-6 months)**, accounting for **$50.7K** of the total revenue at risk.

---

## 📌 Context & Business Problem (Situation)
An established E-commerce platform experienced a declining trend in customer retention, directly impacting monthly recurring revenue streams.
* **Core Challenge:** Management lacked visibility into granular operational data. The legacy data was static, lacked standardized date dimensions, and contained heavy human-input anomalies from external systems.
* **Objective:** Build an automated data pipeline to cleanse operational data, embed Product Owner business logic, and deliver an Executive Dashboard to detect churn risk in real-time.

---

## 🎯 Project Scope & Deliverables (Task)
As an End-to-End Data Analyst, my deliverables included:
1. **Data Engineering:** Transforming static raw data into logical monthly snapshots to establish time-series validity.
2. **Database Modeling:** Developing a centralized Data Mart utilizing a *Bronze-to-Gold* architecture via robust SQL VIEWs.
3. **Business Intelligence:** Designing a robust *Star Schema* data model in Power BI and calculating dynamic business KPIs using advanced DAX.

---

## 🛠️ Data Pipeline & Architecture (Action)

              ┌──────────────────────────────┐
              │   Source: Static CSV Data    │
              └──────────────┬───────────────┘
                             │
                             ▼
     ┌───────────────────────────────────────────────┐
     │     BRONZE LAYER (raw_ecom.e_commerce)       │ --> Defensive Design (VARCHAR)
     └───────────────┬───────────────────────────────┘
                     │
                     ▼
     ┌───────────────────────────────────────────────┐
     │     GOLD LAYER (analytics_gold.dim_churn)     │ --> CTEs, Cleansing, Casting
     └───────────────┬───────────────────────────────┘
                     │
                     ▼
     ┌───────────────────────────────────────────────┐
     │    POWER BI LAYER (Star Schema Modeling)      │ --> DAX & Interactive Slicing
     └───────────────────────────────────────────────┘

### 1. SQL Optimization & Feature Engineering
To maximize efficiency, heavy transformations were pushed upstream to the database engine (**Pushdown Optimization**) within `sql/02_analytics_view_transform.sql`:
* **Advanced Inactivity Churn Rule:** Proactively flagged a customer as churned (`churn_target = 1`) if the historical flag was triggered **OR** if the user was inactive for $\ge$ 60 days.
* **Promo Transaction Ratio:** Calculated the user's discount dependency to isolate *Promo Hunter* behavior profiles:
  $$\text{Promo Ratio} = \frac{\text{coupons\_used\_count}}{\text{order\_count\_12m}}$$

### 2. Power BI Data Modeling (Star Schema)
Data was ingested via *Import Mode* directly from the SQL VIEW layer. The data model was structured using a clean **Star Schema**, mapping the transactional snapshot fact table (`Fact_Customer_Snapshot`) to master dimension tables (`Dim_Customer_Profile` and `Dim_Date`). This approach decoupled complex business logic from the front-end, ensuring instant filter context rendering and zero dashboard lag.

---

## 📊 Data Insights & Commercial Impact (Result)

### 1. Executive Churn Overview (Page 1)
* **Localized Financial Crisis:** Out of **5.63K total customers**, **948 users are actively churned (16.84%)**, exposing a severe **$152.03K Total Revenue at Risk**.
* **Vulnerable Categories:** Users purchasing **Mobile Phones** generated the highest churn volume at **27.40%**, followed by the *Fashion* segment at **15.50%**.

### 2. Behavioral & Promo Analytics (Page 2)
* **Friction & Complaint Correlation:** The platform suffers from a **28.49% Complain Rate**. Granular analysis reveals that **31.67% of complaining customers eventually churn**, pointing to significant friction in customer service or logistics.
* **Promo Hunter Fragility:** The business holds **3.62K Promo Hunters** with an **18.56% churn rate**. Data shows high transaction *recency* decay immediately after coupons are exhausted.

### 3. Customer Cohort & Lifecycle Risk (Page 3)
* **The "U-Curve" Anomaly (Silent Killer):** Granular slicing of *Satisfaction Scores* showed that while low scores (Score 1) naturally lead to high churn, **customers giving a perfect Score 5 unexpectedly exhibit an almost identical high churn rate**. This proves that high app ratings mask a segment of users secretly defecting to competitors due to unfulfilled long-term expectations or aggressive competitor targeting.
* **The Primary Revenue Leak:** The highest financial risk **does not** come from brand-new users (`<1 Month` at $34.2K), but is heavily concentrated in **Junior Users (1-6 Months), leaking a massive $50.7K**.

---

## 📂 Repository Structure
```directory
├── data/
│   ├── raw/                           # Raw e-commerce dataset CSV
│   └── processed/                     # Cleaned data extracts
├── sql/
│   ├── 01_raw_table_setup.sql         # Ingestion / Bronze Layer Setup
│   └── 02_analytics_view_transform.sql # Transformation / Gold Layer View
├── reports/
│   └── ecommerce_churn_analytics.pbix # Power BI Dashboard source file
└── README.md                          # Repository documentation




     
