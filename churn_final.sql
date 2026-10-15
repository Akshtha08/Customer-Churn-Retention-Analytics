/* =====================================================================
   Customer Churn & Retention Analytics: end-to-end SQL script (MySQL 8)
   Run top to bottom. Safe to re-run.

   Source tables (churn_project):
     customers (customer demographics + churn flag)
     services  (internet service, online security, tech support)
     billing   (contract, payment method, monthly / total charges)

   Sections
     0. Setup & data quality checks
     1. Join -> churn_view  (analysis dataset used by Power BI)
     2. Validation
     3. KPIs
     4. Exploratory analysis
     5. Export churn_view to CSV
   ===================================================================== */


/* ---------- 0. SETUP & DATA QUALITY CHECKS ---------- */
USE churn_project;

-- Row counts per source table (expect the same count everywhere)
SELECT (SELECT COUNT(*) FROM customers) AS customers_rows,
       (SELECT COUNT(*) FROM services)  AS services_rows,
       (SELECT COUNT(*) FROM billing)   AS billing_rows;

-- Customers missing a matching row in services or billing (expect 0)
SELECT COUNT(*) AS customers_without_match
FROM customers c
LEFT JOIN services s ON s.customerID = c.customerID
LEFT JOIN billing  b ON b.customerID = c.customerID
WHERE s.customerID IS NULL OR b.customerID IS NULL;

-- Unexpected churn labels (expect only Yes / No)
SELECT Churn, COUNT(*) AS customers FROM customers GROUP BY Churn;

-- Blank or NULL TotalCharges (new customers with tenure 0 in the Telco dataset)
SELECT COUNT(*) AS blank_total_charges
FROM billing
WHERE TotalCharges IS NULL OR TRIM(TotalCharges) = '';


/* ---------- 1. JOIN -> churn_view ---------- */
-- Joins customer, service-level and billing data into one analysis view.
CREATE OR REPLACE VIEW churn_view AS
SELECT c.customerID, c.gender, c.SeniorCitizen, c.Partner, c.Dependents,
       c.tenure, c.Churn,
       s.InternetService, s.OnlineSecurity, s.TechSupport,
       b.Contract, b.PaymentMethod, b.MonthlyCharges, b.TotalCharges
FROM customers c
JOIN services s ON c.customerID = s.customerID
JOIN billing  b ON c.customerID = b.customerID;


/* ---------- 2. VALIDATION ---------- */
-- Expect: view_rows = customers_rows (the joins neither drop nor duplicate customers)
SELECT (SELECT COUNT(*) FROM customers)  AS customers_rows,
       (SELECT COUNT(*) FROM churn_view) AS view_rows;


/* ---------- 3. KPIs (match the dashboard cards) ---------- */
SELECT COUNT(*)                                          AS total_customers,
       SUM(Churn = 'Yes')                                AS customers_lost,
       ROUND(100 * AVG(Churn = 'Yes'), 2)                AS churn_rate_pct,
       ROUND(AVG(MonthlyCharges), 2)                     AS avg_monthly_charges,
       ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges END), 0) AS revenue_at_risk_monthly
FROM churn_view;


/* ---------- 4. EXPLORATORY ANALYSIS ---------- */

-- 4.1 Churn by contract
SELECT Contract, COUNT(*) AS customers,
       ROUND(100 * AVG(Churn = 'Yes'), 2) AS churn_pct,
       ROUND(AVG(MonthlyCharges), 2)      AS avg_monthly
FROM churn_view
GROUP BY Contract
ORDER BY churn_pct DESC;

-- 4.2 Churn by tenure band
SELECT CASE WHEN tenure <= 12 THEN '0-12'
            WHEN tenure <= 24 THEN '13-24'
            WHEN tenure <= 48 THEN '25-48'
            ELSE '49+' END AS tenure_band,
       COUNT(*) AS customers,
       ROUND(100 * AVG(Churn = 'Yes'), 2) AS churn_pct
FROM churn_view
GROUP BY tenure_band
ORDER BY MIN(tenure);

-- 4.3 Churn by internet service
SELECT InternetService, COUNT(*) AS customers,
       ROUND(100 * AVG(Churn = 'Yes'), 2) AS churn_pct,
       ROUND(AVG(MonthlyCharges), 2)      AS avg_monthly
FROM churn_view
GROUP BY InternetService
ORDER BY churn_pct DESC;

-- 4.4 Churn by pricing band (monthly charges)
SELECT CASE WHEN MonthlyCharges < 35 THEN '<35'
            WHEN MonthlyCharges < 70 THEN '35-69'
            ELSE '70+' END AS price_band,
       COUNT(*) AS customers,
       ROUND(100 * AVG(Churn = 'Yes'), 2) AS churn_pct
FROM churn_view
GROUP BY price_band
ORDER BY MIN(MonthlyCharges);

-- 4.5 Churn by payment method
SELECT PaymentMethod, COUNT(*) AS customers,
       ROUND(100 * AVG(Churn = 'Yes'), 2) AS churn_pct
FROM churn_view
GROUP BY PaymentMethod
ORDER BY churn_pct DESC;

-- 4.6 Service-level: tech support and online security
SELECT 'TechSupport' AS feature, TechSupport AS value, COUNT(*) AS customers,
       ROUND(100 * AVG(Churn = 'Yes'), 2) AS churn_pct
FROM churn_view GROUP BY TechSupport
UNION ALL
SELECT 'OnlineSecurity', OnlineSecurity, COUNT(*),
       ROUND(100 * AVG(Churn = 'Yes'), 2)
FROM churn_view GROUP BY OnlineSecurity;

-- 4.7 Senior citizens vs others
SELECT CASE WHEN SeniorCitizen = 1 THEN 'Senior' ELSE 'Non-senior' END AS senior_label,
       COUNT(*) AS customers,
       ROUND(100 * AVG(Churn = 'Yes'), 2) AS churn_pct
FROM churn_view
GROUP BY senior_label;

-- 4.8 Top 5 high-risk segments (at least 50 customers)
SELECT Contract, InternetService, PaymentMethod, COUNT(*) AS customers,
       ROUND(100 * AVG(Churn = 'Yes'), 2) AS churn_pct
FROM churn_view
GROUP BY Contract, InternetService, PaymentMethod
HAVING COUNT(*) >= 50
ORDER BY churn_pct DESC
LIMIT 5;

-- 4.9 Share of lost revenue by contract
SELECT Contract,
       ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges END), 0) AS revenue_lost,
       ROUND(100 * SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges END)
                 / (SELECT SUM(MonthlyCharges) FROM churn_view WHERE Churn = 'Yes'), 1) AS pct_of_lost_revenue
FROM churn_view
GROUP BY Contract
ORDER BY revenue_lost DESC;


/* ---------- 5. EXPORT FOR POWER BI ---------- */
-- Change the path to your secure_file_priv folder (check: SHOW VARIABLES LIKE 'secure_file_priv';)
-- MySQL will not overwrite an existing file: delete churn_view.csv first when re-running.
SELECT 'customerID','gender','SeniorCitizen','Partner','Dependents','tenure','Churn',
       'InternetService','OnlineSecurity','TechSupport','Contract','PaymentMethod',
       'MonthlyCharges','TotalCharges'
UNION ALL
SELECT customerID, gender, SeniorCitizen, Partner, Dependents, tenure, Churn,
       InternetService, OnlineSecurity, TechSupport, Contract, PaymentMethod,
       MonthlyCharges, IFNULL(TotalCharges, '')
FROM churn_view
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/churn_view.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n';