Customer Churn & Retention Analytics

An end-to-end analytics project that identifies why customers leave, who is most at risk, and how much revenue is on the line, using MySQL for data preparation and Power BI for an interactive dashboard.

Show Image

Project Overview
	
Goal	Identify churn patterns, retention trends and high-risk customer segments
Data	Telecom customer subscription data (7,043 customers, contract, tenure, pricing and service attributes)
Tools	MySQL, SQL, Power BI (DAX)
Output	Cleaned SQL view (churn_view), interactive dashboard, retention recommendations
Workflow
Data preparation (MySQL): cleaned raw data, handled blanks and type issues, joined customer and service-level tables, filtered and aggregated into a single analysis view, churn_view.
Exploratory analysis (SQL): examined churn against tenure, contract type, monthly charges, internet service and add-on services.
Dashboard (Power BI): KPI cards, segment-level churn charts, and slicers (contract, tenure band) for interactive filtering.
Recommendations: translated findings into actions for retention teams.
Headline KPIs
KPI	Value
Churn rate	26.54%
Customers lost	1,869
Avg monthly charges	64.76
Revenue at risk (monthly recurring revenue from churned customers)	139,131
Key Findings
Dimension	Highest-risk segment	Churn	Lowest-risk segment	Churn
Contract	Month-to-month	42.71%	Two year	2.83%
Tenure band	0–12 months	47.44%	49+ months	9.51%
Internet service	Fiber optic	41.89%	No internet	7.40%
Online security	No	41.77%	Yes	14.61%
Tech support	No	41.64%	Yes	15.17%
Senior citizen	Senior	41.68%	Non-senior	23.61%

Takeaways

Churn is concentrated in new, month-to-month customers: nearly half of customers in their first year leave.
Customers without Online Security or Tech Support churn about 3x more than those with them.
Fiber optic customers churn at more than double the DSL rate, suggesting a price or service-quality issue worth investigating.
Senior citizens churn at roughly 1.8x the rate of non-seniors.
Recommendations
Onboarding focus on the first 12 months with proactive check-ins and early-life offers.
Incentivize contract upgrades: discounts for moving month-to-month customers to 1–2 year plans.
Bundle Online Security and Tech Support free or discounted for at-risk customers, since both are linked to lower churn.
Review fiber optic pricing and service quality to understand its elevated churn.
Targeted senior-customer support (simplified plans, assisted service).
Repository Structure
├── sql/
│   └── churn_analysis.sql        # data checks, churn_view, KPIs, exploratory queries, CSV export
├── powerbi/
│   └── churncustomers.pbix
├── images/
│   └── dashboard.png
└── README.md
How to Run
Load the dataset into MySQL (tables customers, services, billing) and run sql/churn_analysis.sql top to bottom. It creates churn_view, prints the KPIs and analysis results, and exports the view to CSV.
Open powerbi/churncustomers.pbix in Power BI Desktop and refresh the data source.
