-- ============================================================
-- CUSTOMER CHURN ANALYSIS | SQL PROJECT
-- Database: customer_churn
-- Tables: subscriptions_python, usage_python
-- ============================================================

-- 0. DATABASE AND DATA-TYPE SETUP
CREATE DATABASE customer_churn;

DESCRIBE subscriptions_python;
DESCRIBE usage_python;

SELECT signup_date, churn_date
FROM subscriptions_python
LIMIT 10;

SELECT month
FROM usage_python
LIMIT 10;

ALTER TABLE usage_python
    MODIFY COLUMN month DATE;

ALTER TABLE subscriptions_python
    MODIFY COLUMN signup_date DATE NULL,
    MODIFY COLUMN churn_date DATE NULL;

SELECT age_group
FROM subscriptions_python;


-- ============================================================
-- Q1. DATA EXPLORATION AND VALIDATION
-- ============================================================

-- 1.1 Sample customer records
SELECT
    customer_id,
    signup_date,
    plan_type,
    plan_tier,
    monthly_price,
    churned
FROM subscriptions_python
LIMIT 10;

-- 1.2 Distinct categories
SELECT DISTINCT plan_tier
FROM subscriptions_python;

SELECT DISTINCT plan_type
FROM subscriptions_python;

-- 1.3 Ten most recently churned customers
SELECT customer_id, churned, churn_date
FROM subscriptions_python
WHERE churned = 'yes'
ORDER BY churn_date DESC
LIMIT 10;

-- 1.4 Validate record counts and customer uniqueness
SELECT
    COUNT(*) AS subscription_records,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM subscriptions_python;

SELECT COUNT(*) AS usage_records
FROM usage_python;

-- 1.5 Missing minutes_active values
SELECT
    COUNT(*) AS usage_records,
    SUM(minutes_active IS NULL) AS missing_minutes
FROM usage_python;


-- ============================================================
-- Q2. OVERALL CHURN AND CUSTOMER SEGMENTS
-- ============================================================

-- 2.1 Overall churn metrics
SELECT
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN churned = 'yes' THEN 1 END) AS churned_customers,
    COUNT(CASE WHEN churned = 'no' THEN 1 END) AS active_customers,
    ROUND(
        COUNT(CASE WHEN churned = 'yes' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS churn_rate
FROM subscriptions_python;

-- 2.2 Churn by subscription type
SELECT
    plan_type,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN churned = 'yes' THEN 1 END) AS churned_customers,
    COUNT(CASE WHEN churned = 'no' THEN 1 END) AS active_customers,
    ROUND(
        COUNT(CASE WHEN churned = 'yes' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS churn_rate
FROM subscriptions_python
GROUP BY plan_type;

-- 2.3 Churn by plan tier
SELECT
    plan_tier,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN churned = 'yes' THEN 1 END) AS churned_customers,
    COUNT(CASE WHEN churned = 'no' THEN 1 END) AS active_customers,
    ROUND(
        COUNT(CASE WHEN churned = 'yes' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS churn_rate
FROM subscriptions_python
GROUP BY plan_tier;

-- 2.4 Churn by acquisition channel (groups with more than 300 customers)
SELECT
    acquisition_channel,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN churned = 'yes' THEN 1 END) AS churned_customers,
    ROUND(
        COUNT(CASE WHEN churned = 'yes' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS churn_rate
FROM subscriptions_python
GROUP BY acquisition_channel
HAVING COUNT(customer_id) > 300
ORDER BY churn_rate DESC;

-- 2.5 Average monthly price by churn status
SELECT
    ROUND(AVG(CASE WHEN churned = 'yes' THEN monthly_price END), 2)
        AS churned_customer_avg_price,
    ROUND(AVG(CASE WHEN churned = 'no' THEN monthly_price END), 2)
        AS active_customer_avg_price
FROM subscriptions_python;


-- ============================================================
-- Q3. CUSTOMER ENGAGEMENT ANALYSIS
-- ============================================================

-- 3.1 Join subscriptions and usage tables
SELECT
    s.customer_id,
    s.churned,
    s.plan_type,
    u.month,
    u.workouts_completed,
    u.minutes_active,
    u.classes_booked,
    u.support_tickets
FROM subscriptions_python AS s
INNER JOIN usage_python AS u
    ON s.customer_id = u.customer_id
LIMIT 10;

-- 3.2 Count rows returned by the join
SELECT COUNT(*) AS joined_rows
FROM subscriptions_python AS s
INNER JOIN usage_python AS u
    ON s.customer_id = u.customer_id;

-- 3.3 Average engagement by churn status
SELECT
    s.churned,
    COUNT(DISTINCT s.customer_id) AS customers,
    ROUND(AVG(u.workouts_completed), 2) AS avg_workouts_completed,
    ROUND(AVG(u.minutes_active), 2) AS avg_minutes_active,
    ROUND(AVG(u.classes_booked), 2) AS avg_classes_booked,
    ROUND(AVG(u.support_tickets), 2) AS avg_support_tickets
FROM subscriptions_python AS s
INNER JOIN usage_python AS u
    ON s.customer_id = u.customer_id
GROUP BY s.churned;

-- 3.4 Ten customers with the lowest average monthly workout count
SELECT
    s.customer_id,
    s.churned AS churn_status,
    ROUND(AVG(u.workouts_completed), 2) AS avg_workouts_completed,
    COUNT(*) AS usage_records_available
FROM subscriptions_python AS s
INNER JOIN usage_python AS u
    ON s.customer_id = u.customer_id
GROUP BY s.customer_id, s.churned
ORDER BY avg_workouts_completed, s.customer_id
LIMIT 10;


-- ============================================================
-- Q4. CHURN TRENDS AND CUSTOMER TENURE
-- ============================================================

-- 4.1 Monthly churn counts (sort by month number, not month name)
SELECT
    YEAR(churn_date) AS churn_year,
    MONTH(churn_date) AS churn_month_number,
    MONTHNAME(churn_date) AS churn_month,
    COUNT(*) AS churned_customers
FROM subscriptions_python
WHERE churned = 'yes'
GROUP BY YEAR(churn_date), MONTH(churn_date), MONTHNAME(churn_date)
ORDER BY churn_year, churn_month_number;

-- 4.2 Monthly churn rate; denominator is customers active at month start
WITH monthly_analysis AS (
    SELECT
        DATE_FORMAT(churn_date, '%Y-%m') AS churn_month,
        COUNT(*) AS churned_customers,
        STR_TO_DATE(
            CONCAT(DATE_FORMAT(churn_date, '%Y-%m'), '-01'),
            '%Y-%m-%d'
        ) AS month_start_date
    FROM subscriptions_python
    WHERE churned = 'yes'
    GROUP BY DATE_FORMAT(churn_date, '%Y-%m')
),
active_customers_count AS (
    SELECT
        m.churn_month,
        m.churned_customers,
        m.month_start_date,
        COUNT(
            CASE
                WHEN s.signup_date < m.month_start_date
                 AND (s.churn_date IS NULL OR s.churn_date >= m.month_start_date)
                THEN s.customer_id
            END
        ) AS active_customers_at_start
    FROM monthly_analysis AS m
    CROSS JOIN subscriptions_python AS s
    GROUP BY m.churn_month, m.churned_customers, m.month_start_date
)
SELECT
    churn_month,
    month_start_date,
    active_customers_at_start,
    churned_customers,
    ROUND(
        churned_customers * 100.0 / NULLIF(active_customers_at_start, 0),
        2
    ) AS churn_rate
FROM active_customers_count
ORDER BY churn_month;

-- 4.3 Diagnostic: customers active at the start of July 2024
-- Parentheses matter: AND is evaluated before OR.
SELECT COUNT(customer_id) AS active_customers
FROM subscriptions_python
WHERE signup_date < '2024-07-01'
  AND (churn_date IS NULL OR churn_date >= '2024-07-01');

-- 4.4 Customers churned before December 2025
SELECT COUNT(*) AS churned_before_december_2025
FROM subscriptions_python
WHERE churn_date < '2025-12-01';

-- 4.5 Sign-ups in October and November 2025
SELECT COUNT(*) AS october_signups
FROM subscriptions_python
WHERE signup_date >= '2025-10-01'
  AND signup_date < '2025-11-01';

SELECT COUNT(*) AS november_signups
FROM subscriptions_python
WHERE signup_date >= '2025-11-01'
  AND signup_date < '2025-12-01';

-- 4.6 Active customers at the start of November and December 2025
SELECT
    '2025-11-01' AS month_start,
    COUNT(*) AS active_customers
FROM subscriptions_python
WHERE signup_date < '2025-11-01'
  AND (churn_date IS NULL OR churn_date >= '2025-11-01')
UNION ALL
SELECT
    '2025-12-01' AS month_start,
    COUNT(*) AS active_customers
FROM subscriptions_python
WHERE signup_date < '2025-12-01'
  AND (churn_date IS NULL OR churn_date >= '2025-12-01');

-- 4.7 Tenure in days for each churned customer
SELECT
    customer_id,
    signup_date,
    churn_date,
    DATEDIFF(churn_date, signup_date) AS tenure_days
FROM subscriptions_python
WHERE churned = 'yes'
ORDER BY tenure_days DESC;

-- 4.8 Average, minimum and maximum churned-customer tenure
SELECT
    ROUND(AVG(DATEDIFF(churn_date, signup_date)), 2) AS average_tenure_days,
    MIN(DATEDIFF(churn_date, signup_date)) AS minimum_tenure_days,
    MAX(DATEDIFF(churn_date, signup_date)) AS maximum_tenure_days
FROM subscriptions_python
WHERE churned = 'yes';

-- 4.9 Churned customers grouped into tenure bands
SELECT
    CASE
        WHEN DATEDIFF(churn_date, signup_date) BETWEEN 0 AND 30 THEN '0 TO 30'
        WHEN DATEDIFF(churn_date, signup_date) BETWEEN 31 AND 90 THEN '31 TO 90'
        WHEN DATEDIFF(churn_date, signup_date) BETWEEN 91 AND 180 THEN '91 TO 180'
        WHEN DATEDIFF(churn_date, signup_date) BETWEEN 181 AND 365 THEN '181 TO 365'
        ELSE '365 PLUS'
    END AS tenure_band,
    COUNT(customer_id) AS churned_customers
FROM subscriptions_python
WHERE churned = 'yes'
GROUP BY tenure_band
ORDER BY CASE tenure_band
    WHEN '0 TO 30' THEN 1
    WHEN '31 TO 90' THEN 2
    WHEN '91 TO 180' THEN 3
    WHEN '181 TO 365' THEN 4
    ELSE 5
END;

-- 4.10 Sign-ups and eventual churn by sign-up month
-- This is not a fixed-window cohort churn rate.
SELECT
    DATE_FORMAT(signup_date, '%Y-%m') AS signup_month,
    COUNT(customer_id) AS signed_up_customers,
    COUNT(CASE WHEN churned = 'yes' THEN customer_id END) AS churned_customers,
    ROUND(
        COUNT(CASE WHEN churned = 'yes' THEN customer_id END)
        * 100.0 / COUNT(customer_id),
        2
    ) AS churned_share_of_signup_cohort
FROM subscriptions_python
GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
ORDER BY signup_month;


-- ============================================================
-- Q5. LOW ENGAGEMENT AND FIRST COMPLETE MONTH ANALYSIS
-- ============================================================

-- 5.1 Customers with below-overall-average workouts
SELECT
    customer_id,
    ROUND(AVG(workouts_completed), 2) AS avg_workouts_completed
FROM usage_python
GROUP BY customer_id
HAVING AVG(workouts_completed) < (
    SELECT AVG(workouts_completed)
    FROM usage_python
)
ORDER BY customer_id;

-- 5.2 Add churn status to below-average engagement customers
SELECT
    u.customer_id,
    s.churned AS churn_status,
    ROUND(AVG(u.workouts_completed), 2) AS avg_workouts_completed
FROM usage_python AS u
INNER JOIN subscriptions_python AS s
    ON u.customer_id = s.customer_id
GROUP BY u.customer_id, s.churned
HAVING AVG(u.workouts_completed) < (
    SELECT AVG(workouts_completed)
    FROM usage_python
)
ORDER BY u.customer_id;

-- 5.3 Churn rate for average-or-higher engagement customers
-- The original condition was >= overall average, not < overall average.
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn_status = 'yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        SUM(CASE WHEN churn_status = 'yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS churn_rate
FROM (
    SELECT
        u.customer_id,
        s.churned AS churn_status,
        AVG(u.workouts_completed) AS avg_workouts_completed
    FROM usage_python AS u
    INNER JOIN subscriptions_python AS s
        ON u.customer_id = s.customer_id
    GROUP BY u.customer_id, s.churned
    HAVING AVG(u.workouts_completed) >= (
        SELECT AVG(workouts_completed)
        FROM usage_python
    )
) AS average_or_above_engagement;

-- 5.4 First complete calendar month after sign-up
SELECT
    s.customer_id,
    s.signup_date,
    DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
        AS measurement_month,
    u.workouts_completed,
    s.churned
FROM subscriptions_python AS s
INNER JOIN usage_python AS u
    ON s.customer_id = u.customer_id
   AND u.month = DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
WHERE s.churn_date > LAST_DAY(
          DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
      )
   OR s.churn_date IS NULL
ORDER BY s.signup_date;

-- 5.5 First complete month workouts by eventual churn status
SELECT
    s.churned,
    COUNT(DISTINCT s.customer_id) AS number_of_customers,
    ROUND(AVG(u.workouts_completed), 2) AS avg_first_month_workouts
FROM subscriptions_python AS s
INNER JOIN usage_python AS u
    ON s.customer_id = u.customer_id
   AND u.month = DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
WHERE s.churn_date > LAST_DAY(
          DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
      )
   OR s.churn_date IS NULL
GROUP BY s.churned;

-- 5.6 Validate churn-date counts
SELECT
    COUNT(*) AS total_customers,
    SUM(churn_date IS NULL) AS not_churned,
    SUM(churn_date IS NOT NULL) AS churned
FROM subscriptions_python;

-- 5.7 Classify first complete month eligibility
SELECT
    CASE
        WHEN s.churn_date IS NOT NULL
         AND s.churn_date <= LAST_DAY(
             DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
         ) THEN 'Churned during measurement month'
        WHEN u.customer_id IS NULL THEN 'No usage record'
        ELSE 'Eligible'
    END AS eligibility_status,
    COUNT(*) AS customers
FROM subscriptions_python AS s
LEFT JOIN usage_python AS u
    ON s.customer_id = u.customer_id
   AND u.month = DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
GROUP BY eligibility_status
ORDER BY eligibility_status;

-- 5.8 Customers without first-complete-month usage, by churn status
SELECT
    s.churned,
    COUNT(*) AS customers_without_usage
FROM subscriptions_python AS s
LEFT JOIN usage_python AS u
    ON s.customer_id = u.customer_id
   AND u.month = DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
WHERE u.customer_id IS NULL
GROUP BY s.churned
ORDER BY s.churned;

-- 5.9 Missing first-month usage percentage by churn status
SELECT
    s.churned,
    COUNT(*) AS total_customers,
    SUM(u.customer_id IS NULL) AS customers_without_usage,
    ROUND(SUM(u.customer_id IS NULL) * 100.0 / COUNT(*), 2) AS missing_usage_pct
FROM subscriptions_python AS s
LEFT JOIN usage_python AS u
    ON s.customer_id = u.customer_id
   AND u.month = DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
GROUP BY s.churned
ORDER BY s.churned;

-- 5.10 First-month workouts for customers retained beyond measurement month
SELECT
    s.churned,
    COUNT(*) AS eligible_customers,
    ROUND(AVG(u.workouts_completed), 2) AS avg_first_month_workouts,
    SUM(u.workouts_completed IS NULL) AS null_workout_values
FROM subscriptions_python AS s
INNER JOIN usage_python AS u
    ON s.customer_id = u.customer_id
   AND u.month = DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
WHERE s.churn_date > LAST_DAY(
          DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
      )
   OR s.churn_date IS NULL
GROUP BY s.churned
ORDER BY s.churned;

-- 5.11 Check first complete month against usage-data coverage
SELECT
    COUNT(*) AS customers,
    SUM(
        DATE_ADD(DATE_FORMAT(signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
        > (SELECT MAX(month) FROM usage_python)
    ) AS beyond_usage_coverage,
    SUM(
        DATE_ADD(DATE_FORMAT(signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
        <= (SELECT MAX(month) FROM usage_python)
    ) AS measurement_month_within_coverage
FROM subscriptions_python;

-- 5.12 Usage-data date coverage
SELECT
    MIN(month) AS first_usage_month,
    MAX(month) AS last_usage_month,
    COUNT(DISTINCT month) AS total_usage_months
FROM usage_python;

-- 5.13 Customers missing a first-complete-month usage record
SELECT
    s.customer_id,
    s.signup_date,
    DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
        AS first_complete_month,
    s.churned,
    s.churn_date
FROM subscriptions_python AS s
LEFT JOIN usage_python AS u
    ON s.customer_id = u.customer_id
   AND u.month = DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
WHERE u.customer_id IS NULL
ORDER BY s.signup_date;

-- 5.14 Categorise customers missing first-complete-month usage
SELECT
    CASE
        WHEN s.churn_date IS NOT NULL
         AND s.churn_date < DATE_ADD(
             DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH
         ) THEN 'Churned before measurement month'
        WHEN s.churn_date IS NOT NULL
         AND s.churn_date <= LAST_DAY(
             DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
         ) THEN 'Churned during measurement month'
        ELSE 'No usage row while still subscribed'
    END AS missing_record_category,
    COUNT(*) AS customer_count
FROM subscriptions_python AS s
LEFT JOIN usage_python AS u
    ON s.customer_id = u.customer_id
   AND u.month = DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
WHERE u.customer_id IS NULL
GROUP BY missing_record_category
ORDER BY customer_count DESC;

-- 5.15 Inspect other recorded usage months for customers missing first month
SELECT
    s.customer_id,
    s.signup_date,
    s.churned,
    COUNT(u.month) AS recorded_usage_months,
    MIN(u.month) AS first_recorded_month,
    MAX(u.month) AS last_recorded_month
FROM subscriptions_python AS s
LEFT JOIN usage_python AS u
    ON s.customer_id = u.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM usage_python AS first_month
    WHERE first_month.customer_id = s.customer_id
      AND first_month.month = DATE_ADD(
          DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH
      )
)
AND (
    s.churn_date IS NULL
    OR s.churn_date >= DATE_ADD(
        DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH
    )
)
GROUP BY s.customer_id, s.signup_date, s.churned
ORDER BY recorded_usage_months;


-- ============================================================
-- Q6. FIRST-MONTH ENGAGEMENT RANKING AND MONTHLY CHANGE
-- ============================================================

-- 6.1 Rank customers by first complete month workouts
WITH customer_engagement AS (
    SELECT
        s.customer_id,
        s.signup_date,
        DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
            AS first_complete_month_on,
        s.churned,
        ROUND(AVG(u.workouts_completed), 2) AS avg_first_month_workouts
    FROM subscriptions_python AS s
    INNER JOIN usage_python AS u
        ON s.customer_id = u.customer_id
       AND u.month = DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
    WHERE s.churn_date > LAST_DAY(
              DATE_ADD(DATE_FORMAT(s.signup_date, '%Y-%m-01'), INTERVAL 1 MONTH)
          )
       OR s.churn_date IS NULL
    GROUP BY s.customer_id, s.signup_date, s.churned
)
SELECT
    customer_id,
    signup_date,
    first_complete_month_on,
    churned,
    avg_first_month_workouts,
    RANK() OVER (ORDER BY avg_first_month_workouts DESC) AS ranking
FROM customer_engagement
ORDER BY ranking;

-- 6.2 Compare workouts with the previous recorded month
SELECT
    customer_id,
    month,
    workouts_completed,
    LAG(workouts_completed) OVER (
        PARTITION BY customer_id
        ORDER BY month
    ) AS previous_month_workouts,
    workouts_completed - LAG(workouts_completed) OVER (
        PARTITION BY customer_id
        ORDER BY month
    ) AS workout_change
FROM usage_python;


-- ============================================================
-- Q7. SEGMENT COMPARISON AND TARGETED ENGAGEMENT ANALYSIS
-- ============================================================

-- 7.1 Churn by plan type and acquisition channel vs. overall churn
WITH customer_segments AS (
    SELECT
        plan_type,
        acquisition_channel,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN churned = 'yes' THEN 1 ELSE 0 END) AS churned_customers
    FROM subscriptions_python
    GROUP BY plan_type, acquisition_channel
),
churn_percentage AS (
    SELECT
        plan_type,
        acquisition_channel,
        total_customers,
        churned_customers,
        ROUND(churned_customers * 100.0 / total_customers, 2)
            AS churn_rate_percentage
    FROM customer_segments
),
overall AS (
    SELECT
        ROUND(
            SUM(CASE WHEN churned = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ) AS overall_churn_rate
    FROM subscriptions_python
)
SELECT
    cp.plan_type,
    cp.acquisition_channel,
    cp.total_customers,
    cp.churned_customers,
    cp.churn_rate_percentage,
    o.overall_churn_rate,
    cp.churn_rate_percentage - o.overall_churn_rate AS difference_from_overall_pp
FROM churn_percentage AS cp
CROSS JOIN overall AS o
ORDER BY difference_from_overall_pp DESC;

-- 7.2 Engagement and churn among monthly promo-offer customers
WITH customer_average AS (
    SELECT
        s.customer_id,
        s.plan_type,
        s.acquisition_channel,
        s.churned,
        AVG(u.workouts_completed) AS avg_workouts
    FROM subscriptions_python AS s
    INNER JOIN usage_python AS u
        ON s.customer_id = u.customer_id
    WHERE s.plan_type = 'monthly'
      AND s.acquisition_channel = 'promo_offer'
    GROUP BY
        s.customer_id,
        s.plan_type,
        s.acquisition_channel,
        s.churned
)
SELECT
    CASE
        WHEN avg_workouts < 4.33 THEN 'Below Average'
        ELSE 'Average or Above'
    END AS engagement_level,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churned = 'yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        SUM(CASE WHEN churned = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS churn_rate
FROM customer_average
GROUP BY engagement_level
ORDER BY churn_rate DESC;


-- ============================================================
-- Q8. QUERY PERFORMANCE AND INDEXING
-- ============================================================

-- 8.1 Inspect execution plan for the customer-level join
EXPLAIN
SELECT
    s.customer_id,
    s.plan_type,
    AVG(u.workouts_completed) AS avg_workouts
FROM subscriptions_python AS s
INNER JOIN usage_python AS u
    ON s.customer_id = u.customer_id
GROUP BY s.customer_id, s.plan_type;

-- 8.2 Create indexes on join keys.
-- Run these CREATE INDEX statements only once.
CREATE INDEX idx_subscriptions_customer_id
    ON subscriptions_python(customer_id);

CREATE INDEX idx_usage_customer_id
    ON usage_python(customer_id);

-- Re-run the EXPLAIN query above to compare the execution plan.
