# Customer Churn Analysis

## Project Overview
This project analyses customer churn for a subscription-based business using Python, SQL, and Power BI. The objective is to identify customer behaviour patterns, understand factors associated with churn, and provide actionable business recommendations.

## Objectives
- Analyse overall customer churn and retention.
- Compare churn across subscription plans and acquisition channels.
- Investigate customer engagement patterns.
- Understand common cancellation reasons.
- Examine monthly-equivalent revenue exposure associated with churn.

## Tools & Technologies
- Python (Pandas, NumPy, Matplotlib, Seaborn)
- SQL (MySQL)
- Power BI (DAX)
- Jupyter Notebook
- Excel

## Key Findings

| Metric | Result |
|---|---:|
| Total Customers | 4,200 |
| Churned Customers | 1,768 |
| Active Customers | 2,432 |
| Overall Churn Rate | 42.10% |
| Monthly Plan Churn | 51.18% |
| Annual Plan Churn | 26.38% |

### Important Insights
1. Monthly subscribers have a considerably higher churn rate than annual subscribers.
2. Customers who churned had lower average engagement than active customers.
3. The most frequently reported cancellation reason was insufficient usage.
4. Customers acquired through promotional offers showed the highest churn rate among acquisition channels.

## Business Recommendations
- Investigate the reasons behind higher churn among monthly subscribers.
- Introduce targeted engagement campaigns for customers with declining activity.
- Improve onboarding to encourage regular product usage.
- Review pricing and perceived value.
- Address technical issues that contribute to cancellations.

## Project Structure
- `notebooks/` – Python data cleaning and analysis.
- `sql/` – SQL queries and business analysis.
- `Power bi/` – Interactive dashboard and preview.
- `requirements.txt` – Python dependencies.
- `.gitignore` – Files excluded from version control.

## Limitations
- The analysis is based on the available dataset and its recorded observation period.
- Missing activity values were not automatically treated as zero.
- Monthly-equivalent revenue exposure is not equivalent to verified lost cash revenue.
- The findings show associations and do not establish causation.

## Dataset
Source: [Data Career School – Customer Churn Analysis](https://datacareerschool.com/datalabs/customer-churn-analysis)

## Author
BCA Graduate | Aspiring Data Analyst

