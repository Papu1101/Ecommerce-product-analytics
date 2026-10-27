# 🛒 E-Commerce Product Analytics: Customer Engagement, Conversion & Retention

An end-to-end data analytics project exploring customer behavior, purchasing patterns, conversion performance, retention, and product performance using **Python, PostgreSQL, and Power BI**.

The project combines exploratory data analysis, SQL-based analysis, customer segmentation, cohort analysis, machine learning, and interactive dashboards to transform raw e-commerce data into actionable business insights.

> **Dataset note:** This project uses synthetic e-commerce data created for analytical learning and prototyping. The findings represent patterns within the generated dataset and should not be interpreted as real-world business results.

---

## 📌 Project Overview

Understanding how customers discover products, interact with an e-commerce platform, make purchases, and return over time is essential for improving business performance.

This project analyzes five interconnected datasets to investigate:

* How frequently customers engage with the platform.
* Which marketing channels and devices generate higher conversion rates.
* How customer segments differ in purchasing behavior and lifetime value.
* How customer retention changes across signup cohorts.
* Which customers may be at risk of churn.
* Which products perform well and offer opportunities for further growth.

The goal is to connect customer engagement, conversion, retention, and revenue metrics to support data-driven business decisions.

---

## 🎯 Business Objectives

1. Measure customer engagement using Daily, Weekly, and Monthly Active Users (DAU, WAU, and MAU).
2. Analyze sales performance, revenue trends, transaction status, and product contribution.
3. Evaluate session conversion rates across marketing channels and devices.
4. Understand browsing behavior, cart additions, and the conversion funnel.
5. Segment customers using Recency, Frequency, and Monetary (RFM) analysis.
6. Analyze customer retention using cohort-based analysis.
7. Predict customer lifetime value and identify churn-related patterns.
8. Evaluate product ratings, discounts, purchasing frequency, and inventory.
9. Develop interactive Power BI dashboards for exploring business performance.

---

## 🗂️ Dataset Overview

The project contains five interconnected synthetic datasets.

| Dataset      |     Records | Purpose                                                                              |
| ------------ | ----------: | ------------------------------------------------------------------------------------ |
| Customers    |      10,000 | Customer demographics, signup dates, segments, churn labels, and lifetime value      |
| Products     |       1,000 | Product categories, brands, prices, ratings, discounts, and inventory                |
| Transactions |     120,000 | Purchases, transaction values, quantities, payment methods, and transaction statuses |
| Sessions     |      80,000 | Customer activity, browsing behavior, marketing channels, devices, and conversions   |
| Reviews      |      25,000 | Product ratings, review text, helpful votes, and verified purchases                  |
| **Total**    | **236,000** | **Five datasets combined**                                                           |

### Key Data Relationships

The datasets are connected through customer and product identifiers:

* Customers → Transactions
* Products → Transactions
* Customers → Sessions
* Customers → Reviews
* Products → Reviews

These relationships support integrated analysis of customer activity, purchasing behavior, and product performance.

---

## 🛠️ Tools & Technologies

| Tool                 | Usage                                                                                |
| -------------------- | ------------------------------------------------------------------------------------ |
| Python               | Data cleaning, exploratory analysis, feature engineering, segmentation, and modeling |
| Pandas & NumPy       | Data manipulation, aggregation, and numerical calculations                           |
| Matplotlib & Seaborn | Data visualization                                                                   |
| PostgreSQL           | Relational data analysis and business queries                                        |
| pgAdmin 4            | Database exploration and SQL query execution                                         |
| Power BI             | Interactive dashboards, KPI cards, charts, and business reporting                    |
| Scikit-learn         | Customer lifetime value prediction and churn classification                          |
| Jupyter Notebook     | Analysis workflow, experimentation, and documentation                                |

---

## 🔍 Project Workflow

### 1. Data Loading and Preparation

Loaded the five datasets into Python and examined their structure, dimensions, column types, and sample records.

Key preparation activities included:

* Inspecting data types and date columns.
* Checking missing values and duplicate records.
* Validating primary keys and foreign-key relationships.
* Checking transaction prices, discounts, and review ratings.
* Preparing data for customer, product, transaction, and session analysis.
* Investigating inconsistencies between customer signup dates and recorded activities.

### 2. Exploratory Data Analysis (EDA)

Explored customer demographics, product categories, transaction statuses, customer activity, browsing behavior, and product reviews.

EDA helped identify important patterns and informed the selection of business KPIs and subsequent analytical methods.

### 3. SQL Analysis with PostgreSQL

Used PostgreSQL to query the relational datasets and investigate business questions involving:

* Revenue and completed transactions.
* Customer purchasing behavior.
* Product and category performance.
* Customer segments.
* Transaction statuses.
* Conversion and engagement metrics.

### 4. Customer Engagement Analysis

Calculated unique active customers over daily, weekly, and monthly periods.

Key metrics included:

* **DAU:** Daily Active Users.
* **WAU:** Weekly Active Users.
* **MAU:** Monthly Active Users.
* **DAU/MAU Stickiness:** Average daily active users relative to monthly active users.

These metrics provide a view of platform engagement and how frequently customers return.

### 5. Funnel and Conversion Analysis

Evaluated the relationship between browsing sessions, cart additions, and conversions.

The analysis compared conversion performance across:

* Marketing channels.
* Devices.
* Customer segments.
* Levels of browsing activity.
* Sessions with and without cart additions.

### 6. Customer Segmentation and Retention

Applied RFM analysis to completed purchasing activity using:

* **Recency:** Days since the customer's most recent purchase.
* **Frequency:** Number of completed transactions.
* **Monetary Value:** Total purchase value.

Customers were grouped into behavioral segments, including Best Customers, Loyal Customers, Potential Loyalists, At Risk, and Need Attention.

Cohort analysis was also used to examine customer activity over time relative to signup cohorts.

### 7. Predictive Modeling

Developed machine learning models for two business problems:

* **Customer Lifetime Value Prediction:** Used a Random Forest Regressor to estimate customer lifetime value.
* **Customer Churn Classification:** Used a Random Forest Classifier to identify customers labeled as churned.

Evaluated model performance using regression and classification metrics, including R², accuracy, recall, and ROC-AUC.

### 8. Power BI Reporting

Created a five-page interactive Power BI report to bring the analytical findings together.

The report includes KPI cards, charts, comparisons, and filters for exploring business performance across different dimensions.

---

## 📊 Key Findings

The following results were obtained from the synthetic dataset during analysis.

### Customer Engagement

| Metric                     | Result |
| -------------------------- | -----: |
| Average DAU                |    109 |
| Highest DAU                |    146 |
| Lowest DAU                 |     80 |
| Average WAU                |    718 |
| Highest WAU                |    793 |
| Average MAU                |  2,712 |
| Highest MAU                |  2,825 |
| Lowest MAU                 |  2,561 |
| Average DAU/MAU Stickiness |  4.01% |

The average monthly active customer count was approximately 2,712. Average DAU/MAU stickiness was 4.01%, providing a baseline for understanding daily engagement relative to the monthly active audience.

The lowest reported WAU was 118 in the initial partial week, so it should not be compared directly with full-week values.

### Revenue and Transactions

| Metric                                   |       Result |
| ---------------------------------------- | -----------: |
| Total Transactions                       |      120,000 |
| Completed Transactions                   |       68,700 |
| Completed Transaction Revenue            | 5,443,245.13 |
| Average Value of a Completed Transaction |        79.23 |
| Customers with Completed Purchases       |        9,730 |

Completed transactions accounted for 68,700 of the 120,000 transaction records.

Revenue metrics use completed transactions, while transaction-status analysis includes completed, refunded, cancelled, and pending records.

### Conversion and Funnel Performance

| Metric                              | Result |
| ----------------------------------- | -----: |
| Total Sessions                      | 80,000 |
| Converted Sessions                  |  8,648 |
| Overall Session Conversion Rate     | 10.81% |
| Sessions with Cart Additions        | 37,229 |
| Sessions with Cart Additions        | 46.54% |
| Conversion Rate Among Cart Sessions | 23.23% |

**Marketing channel performance**

| Channel | Conversion Rate |
| ------- | --------------: |
| Social  |          11.27% |
| Organic |          10.43% |

Social recorded the highest conversion rate among the reported channels, while organic recorded the lowest.

**Device performance**

| Device  | Conversion Rate |
| ------- | --------------: |
| Desktop |          11.07% |
| Mobile  |          10.75% |
| Tablet  |          10.40% |

Desktop sessions had the highest conversion rate among the three device categories.

**Browsing behavior**

* Sessions with 10 or more pages viewed had a conversion rate of 13.79%.
* Sessions with 1–2 pages viewed had a conversion rate of 9.59%.
* VIP customers had the highest reported segment conversion rate at 18.32%.
* Occasional Visitors had the lowest reported segment conversion rate at 1.86%.

These patterns suggest that browsing depth and customer segment are useful dimensions for further conversion analysis.

**CTR limitation:** Click-through rate requires click and impression counts. These fields were not available in the documented dataset columns, so CTR was not calculated as a validated project result.

### Customer Lifetime Value and Churn

| Metric                          |   Result |
| ------------------------------- | -------: |
| Average Customer Lifetime Value | 1,544.61 |
| Median Customer Lifetime Value  | 1,043.80 |
| Customers Labeled as Churned    |   16.94% |

Average lifetime value was higher than median lifetime value, indicating variation in customer value.

The churn rate represents the proportion of customers labeled as churned in the dataset; it does not independently establish the cause of churn.

### Machine Learning Results

**Customer Lifetime Value Prediction**

| Metric   |                  Result |
| -------- | ----------------------: |
| Model    | Random Forest Regressor |
| R² Score |                  0.8484 |

The model achieved an R² score of 0.8484 in the reported evaluation. Customer segment emerged as the most influential predictor in the feature-importance analysis.

**Customer Churn Classification**

| Metric       |                   Result |
| ------------ | -----------------------: |
| Model        | Random Forest Classifier |
| Accuracy     |                      73% |
| Churn Recall |                      25% |
| ROC-AUC      |                   0.5801 |

Although the churn model achieved 73% accuracy, its 25% recall indicates that it identified only a limited proportion of customers labeled as churned. Its ROC-AUC of 0.5801 also indicates weak discrimination.

Accuracy alone is therefore insufficient to judge this model's usefulness. Improving churn recall and overall predictive performance would be important next steps.

### Product Recommendations

Product P0405 had the highest purchase count among the reported top ten products, appearing in 103 completed transactions.

Traditional market-basket association analysis was limited because each transaction contained only one unique product. Popularity-based recommendations remain a feasible alternative with the available data.

---

## 📈 Power BI Dashboard

The Power BI report is organized into five pages.

### 1. Executive Overview

Provides a high-level view of business performance through:

* Completed revenue.
* Completed transactions.
* Purchasing customers.
* Average transaction value.
* Refund rate.
* Monthly revenue trends.
* Revenue by product category.
* Transaction status distribution.
* Customer segment distribution.

### 2. Revenue & Sales Analysis

Focuses on transaction performance and product revenue through:

* Revenue and transaction KPIs.
* Top products by revenue.
* Revenue by customer segment.
* Monthly revenue growth.
* Product revenue contribution.

### 3. Customer Analytics

Explores customer value and churn through:

* Customer and churn KPIs.
* Churn by customer segment.
* Average lifetime value by segment.
* Monthly customer signups.
* Customer segment and churn comparisons.
* Customer age distribution.

### 4. Funnel & Marketing Analytics

Evaluates session behavior and conversion through:

* Total and converted sessions.
* Conversion rate by marketing channel.
* Bounce rate by device.
* Session conversion funnel.
* Channel and device comparisons.

### 5. Product Performance

Examines product quality, revenue, and inventory through:

* Product count and rating KPIs.
* Product rating versus revenue.
* Discount versus revenue.
* Revenue by brand.
* Inventory distribution.
* Product-level details.

The dashboards include interactive filters for exploring available date, category, segment, country, and other relevant dimensions.

---

## 💡 Business Recommendations

Based on the reported findings, the following opportunities merit further investigation:

1. **Improve retention:** Investigate the needs of At Risk and Need Attention customer segments and evaluate targeted retention campaigns.
2. **Optimize marketing:** Study why social sessions convert at a higher rate than organic sessions and test whether its performance is repeatable.
3. **Improve mobile conversion:** Examine the mobile purchasing journey for usability issues that could explain its lower conversion rate relative to desktop.
4. **Reduce funnel friction:** Investigate the relationship between cart additions and purchases to identify potential opportunities for improving checkout completion.
5. **Prioritize high-value customers:** Use RFM segments and lifetime value estimates to support differentiated customer engagement strategies.
6. **Improve churn prediction:** Focus on improving churn recall and ROC-AUC before using model predictions to guide customer outreach.
7. **Strengthen product recommendations:** Explore popularity-based recommendations and collect multi-item basket data if association-rule analysis is a future priority.
8. **Improve tracking quality:** Validate customer signup dates, activity timestamps, and marketing event tracking before using the metrics for operational decisions.

These are proposed opportunities, not proven causal effects. They should be validated through further analysis or controlled experiments.

---

## ⚠️ Data Quality and Analytical Limitations

The analysis identified several limitations that affect interpretation:

* The data is synthetic and does not represent verified real-world business performance.
* The analysis identified 11,027 transactions and 7,294 sessions dated before the associated customers' signup dates.
* Date-related inconsistencies require careful treatment in cohort and customer-lifecycle analysis.
* CTR could not be calculated because click and impression counts were not available in the documented fields.
* Each transaction contained only one unique product, limiting traditional basket-level association analysis.
* The churn model's recall and ROC-AUC were low, so its predictions should not be treated as a reliable standalone basis for intervention.
* Power BI KPI definitions, filters, and aggregation logic should be checked against the Python results before publishing final metrics.

---

## 🚀 Skills Demonstrated

* Data cleaning and validation.
* Exploratory data analysis.
* SQL querying and relational analysis.
* KPI definition and calculation.
* Customer engagement analytics.
* Conversion funnel analysis.
* Cohort retention analysis.
* RFM customer segmentation.
* Customer lifetime value prediction.
* Churn classification and model evaluation.
* Product performance analysis.
* Interactive dashboard design and data storytelling.

---

## 🔮 Future Improvements

* Add validated click and impression data to calculate CTR.
* Improve churn-model recall and ROC-AUC through feature engineering, model comparison, and threshold tuning.
* Add purchase-level multi-item basket data for market-basket analysis.
* Refine cohort definitions and handle inconsistent event timestamps.
* Reconcile Power BI KPIs with Python and SQL calculations.
* Add automated data-quality checks and repeatable analysis workflows.
* Extend the dashboard with validated retention, repeat-purchase, and customer acquisition metrics.

---

## 📁 Project Structure

A suggested repository structure is:

```text
ecommerce-product-analytics/
│
├── data/
│   ├── customers.csv
│   ├── products.csv
│   ├── transactions.csv
│   ├── sessions.csv
│   └── reviews.csv
│
├── notebooks/
│   └── Prodcut_Analysis.ipynb
│
├── sql/
│   └── ecommerce_analysis.sql
│
├── powerbi/
│   └── ecommerce_product_analytics.pbix
│
├── images/
│   └── dashboard_screenshots/
│
└── README.md
```

*This is a suggested structure. Include only files and folders that you actually add to your repository, and adjust the filenames to match your saved files.*

---

## ▶️ Getting Started

### Prerequisites

* Python 3.x
* Jupyter Notebook
* PostgreSQL
* pgAdmin 4
* Power BI Desktop

### Python Libraries

The analysis uses libraries including:

```bash
pip install pandas numpy matplotlib seaborn scipy statsmodels scikit-learn sqlalchemy mlxtend
```

### Run the Analysis

1. Clone or download the repository.
2. Place the datasets in the expected data directory.
3. Install the required Python libraries.
4. Open the analysis notebook in Jupyter Notebook.
5. Update the dataset paths and database connection settings as needed.
6. Run the notebook cells in order.
7. Load the prepared data into PostgreSQL to execute the SQL analysis.
8. Open the Power BI report in Power BI Desktop and verify its data connections.

---

## 📌 Conclusion

This project demonstrates an end-to-end approach to e-commerce analytics, connecting data preparation, SQL analysis, customer engagement metrics, conversion funnels, retention, segmentation, predictive modeling, and Power BI reporting.

The findings provide a foundation for investigating customer behavior and identifying opportunities to improve engagement, conversion, retention, and product performance.

**Technologies:** Python · Pandas · NumPy · PostgreSQL · SQL · Power BI · Scikit-learn

**Project Type:** Data Analytics · Product Analytics · Customer Analytics · Business Intelligence · Machine Learning

