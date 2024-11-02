CREATE TABLE sales_data (
    date_new DATE,
    id_check BIGINT,
    id_client BIGINT,
    count_products NUMERIC,
    sum_payment NUMERIC
);

CREATE TABLE customer_info (
    id_client BIGINT,
    total_amount NUMERIC,
    gender CHAR(1),
    age INT,
    count_city INT,
    response_communication INT,
    communication_3month INT,
    tenure INT
);


WITH monthly_sales AS (
    SELECT 
        id_client,
        DATE_TRUNC('month', date_new) AS transaction_month,
        COUNT(*) AS transactions_per_month,
        SUM(sum_payment) AS total_amount_per_month
    FROM 
        sales_data
    WHERE 
        date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY 
        id_client, DATE_TRUNC('month', date_new)
),
continuous_clients AS (
    SELECT 
        id_client
    FROM 
        monthly_sales
    GROUP BY 
        id_client
    HAVING 
        COUNT(DISTINCT transaction_month) = 12  -- Ensures every month is covered
)
SELECT 
    c.id_client,
    AVG(s.sum_payment) AS average_receipt,   -- Average receipt per transaction
    AVG(monthly.total_amount_per_month) AS average_monthly_purchase,  -- Average monthly amount
    COUNT(s.id_check) AS total_transactions   -- Total transactions in the period
FROM 
    continuous_clients cc
JOIN 
    customer_info c ON cc.id_client = c.id_client
JOIN 
    sales_data s ON c.id_client = s.id_client
JOIN 
    monthly_sales monthly ON monthly.id_client = c.id_client
WHERE 
    s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    c.id_client;



SELECT 
    DATE_TRUNC('month', s.date_new) AS transaction_month,
    AVG(s.sum_payment) AS avg_check_amount
FROM 
    sales_data s
WHERE 
    s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    transaction_month
ORDER BY 
    transaction_month;


SELECT 
    DATE_TRUNC('month', s.date_new) AS transaction_month,
    COUNT(s.id_check) AS avg_operations_per_month
FROM 
    sales_data s
WHERE 
    s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    transaction_month
ORDER BY 
    transaction_month;

SELECT 
    DATE_TRUNC('month', s.date_new) AS transaction_month,
    COUNT(DISTINCT s.id_client) AS avg_clients_per_month
FROM 
    sales_data s
WHERE 
    s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    transaction_month
ORDER BY 
    transaction_month;


WITH total_yearly AS (
    SELECT 
        COUNT(*) AS total_yearly_transactions,
        SUM(s.sum_payment) AS total_yearly_payment
    FROM 
        sales_data s
    WHERE 
        s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
)

SELECT 
    DATE_TRUNC('month', s.date_new) AS transaction_month,
    COUNT(s.id_check)::DECIMAL / NULLIF((SELECT total_yearly_transactions FROM total_yearly), 0) * 100 AS monthly_transaction_share,
    SUM(s.sum_payment) / NULLIF((SELECT total_yearly_payment FROM total_yearly), 0) * 100 AS monthly_payment_share
FROM 
    sales_data s
WHERE 
    s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    transaction_month
ORDER BY 
    transaction_month;


WITH gender_totals AS (
    SELECT 
        DATE_TRUNC('month', s.date_new) AS transaction_month,
        COUNT(s.id_check) AS total_transactions,
        SUM(s.sum_payment) AS total_payment
    FROM 
        sales_data s
    WHERE 
        s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY 
        transaction_month
),
gender_data AS (
    SELECT 
        DATE_TRUNC('month', s.date_new) AS transaction_month,
        c.gender,
        COUNT(s.id_check) AS gender_count,
        SUM(s.sum_payment) AS gender_total
    FROM 
        sales_data s
    JOIN 
        customer_info c ON s.id_client = c.id_client
    WHERE 
        s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY 
        transaction_month, c.gender
)

SELECT 
    g.transaction_month,
    SUM(CASE WHEN g.gender = 'M' THEN g.gender_count ELSE 0 END)::DECIMAL / NULLIF(SUM(g.gender_count), 0) * 100 AS male_percentage,
    SUM(CASE WHEN g.gender = 'F' THEN g.gender_count ELSE 0 END)::DECIMAL / NULLIF(SUM(g.gender_count), 0) * 100 AS female_percentage,
    SUM(CASE WHEN g.gender IS NULL THEN g.gender_count ELSE 0 END)::DECIMAL / NULLIF(SUM(g.gender_count), 0) * 100 AS na_percentage,
    SUM(CASE WHEN g.gender = 'M' THEN g.gender_total ELSE 0 END)::DECIMAL / NULLIF(SUM(t.total_payment), 0) * 100 AS male_cost_share,
    SUM(CASE WHEN g.gender = 'F' THEN g.gender_total ELSE 0 END)::DECIMAL / NULLIF(SUM(t.total_payment), 0) * 100 AS female_cost_share,
    SUM(CASE WHEN g.gender IS NULL THEN g.gender_total ELSE 0 END)::DECIMAL / NULLIF(SUM(t.total_payment), 0) * 100 AS na_cost_share
FROM 
    gender_data g
JOIN 
    gender_totals t ON g.transaction_month = t.transaction_month
GROUP BY 
    g.transaction_month
ORDER BY 
    g.transaction_month;




-- Total amount and number of transactions for age groups
WITH age_groups AS (
    SELECT 
        CASE 
            WHEN c.age IS NULL THEN 'Unknown'
            WHEN c.age < 20 THEN '0-19'
            WHEN c.age < 30 THEN '20-29'
            WHEN c.age < 40 THEN '30-39'
            WHEN c.age < 50 THEN '40-49'
            WHEN c.age < 60 THEN '50-59'
            WHEN c.age < 70 THEN '60-69'
            WHEN c.age < 80 THEN '70-79'
            ELSE '80+' 
        END AS age_group,
        COUNT(s.id_check) AS total_transactions,
        SUM(s.sum_payment) AS total_amount
    FROM 
        sales_data s
    JOIN 
        customer_info c ON s.id_client = c.id_client
    WHERE 
        s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY 
        age_group
)

SELECT 
    age_group,
    total_transactions,
    total_amount,
    ROUND(total_amount::DECIMAL / NULLIF(total_transactions, 0), 2) AS avg_amount_per_transaction
FROM 
    age_groups
ORDER BY 
    age_group;

-- Quarterly averages and percentages
WITH quarterly_data AS (
    SELECT 
        DATE_TRUNC('quarter', s.date_new) AS transaction_quarter,
        CASE 
            WHEN c.age IS NULL THEN 'Unknown'
            WHEN c.age < 20 THEN '0-19'
            WHEN c.age < 30 THEN '20-29'
            WHEN c.age < 40 THEN '30-39'
            WHEN c.age < 50 THEN '40-49'
            WHEN c.age < 60 THEN '50-59'
            WHEN c.age < 70 THEN '60-69'
            WHEN c.age < 80 THEN '70-79'
            ELSE '80+' 
        END AS age_group,
        COUNT(s.id_check) AS quarterly_transactions,
        SUM(s.sum_payment) AS quarterly_amount
    FROM 
        sales_data s
    JOIN 
        customer_info c ON s.id_client = c.id_client
    WHERE 
        s.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY 
        transaction_quarter, age_group
)

SELECT 
    transaction_quarter,
    age_group,
    AVG(quarterly_transactions) AS avg_transactions,
    AVG(quarterly_amount) AS avg_amount,
    (SUM(quarterly_transactions) * 100.0 / SUM(SUM(quarterly_transactions)) OVER ()) AS percentage_of_total_transactions,
    (SUM(quarterly_amount) * 100.0 / SUM(SUM(quarterly_amount)) OVER ()) AS percentage_of_total_amount
FROM 
    quarterly_data
GROUP BY 
    transaction_quarter, age_group
ORDER BY 
    transaction_quarter, age_group;

