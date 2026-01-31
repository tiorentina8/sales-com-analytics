SELECT COUNT(*) 
FROM information_schema.tables 
WHERE table_schema = 'public';

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- Accounts table
CREATE TABLE accounts (
    account VARCHAR(150) PRIMARY KEY,
    sector VARCHAR(50),
    year_established INT,
    revenue NUMERIC(12,2),
    employees INT,
    office_location VARCHAR(100),
    subsidiary_of VARCHAR(150)
);

-- Products table
CREATE TABLE products (
    product VARCHAR(100) PRIMARY KEY,
    series VARCHAR(50),
    sales_price NUMERIC(12,2)
);

-- Sales Teams table
CREATE TABLE sales_teams (
    sales_agent VARCHAR(100) PRIMARY KEY,
    manager VARCHAR(100),
    regional_office VARCHAR(50)
);

-- Sales Pipeline table
CREATE TABLE sales_pipeline (
    opportunity_id VARCHAR(20) PRIMARY KEY,
    sales_agent VARCHAR(100),
    product VARCHAR(100),
    account VARCHAR(150),
    deal_stage VARCHAR(50),
    engage_date DATE,
    close_date DATE,
    close_value NUMERIC(12,2)
);

copy accounts(account, sector, year_established, revenue, employees, office_location, subsidiary_of)
FROM '/tmp/csv/accounts.csv'
DELIMITER ',' CSV HEADER;

copy products(product, series, sales_price)
FROM '/tmp/csv/products.csv'
DELIMITER ',' CSV HEADER;

copy sales_teams(sales_agent, manager, regional_office)
FROM '/tmp/csv/sales_teams.csv'
DELIMITER ',' CSV HEADER;

copy sales_pipeline(opportunity_id, sales_agent, product, account, deal_stage, engage_date, close_date, close_value)
FROM '/tmp/csv/sales_pipeline.csv'
DELIMITER ',' CSV HEADER;

SELECT COUNT(*) FROM accounts;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM sales_teams;
SELECT COUNT(*) FROM sales_pipeline;


SELECT * FROM accounts
SELECT * FROM products
SELECT * FROM sales_teams
SELECT * FROM sales_pipeline


-- medical sector companies with revenue greater than $500 million
SELECT *
FROM accounts
WHERE sector = 'medical'
  AND revenue > 500;

-- top performing sector by average deal value
SELECT a.sector,
       AVG(sp.close_value) AS avg_deal_value,
       COUNT(sp.opportunity_id) AS total_deals
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE sp.deal_stage = 'Won'
GROUP BY a.sector
ORDER BY avg_deal_value DESC;

-- revenue by subsidiary group

SELECT COALESCE(a.subsidiary_of, a.account) AS parent_company,
       SUM(a.revenue) AS total_group_revenue,
       COUNT(*) AS num_companies
FROM accounts a
GROUP BY COALESCE(a.subsidiary_of, a.account)
ORDER BY total_group_revenue DESC;

-- conversion rate by sector 

SELECT a.sector,
       SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END)::float /
       COUNT(sp.opportunity_id) * 100 AS conversion_rate
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
GROUP BY a.sector
ORDER BY conversion_rate DESC;

-- top sales agent by total closed value

SELECT sp.sales_agent,
       SUM(sp.close_value) AS total_closed_value,
       COUNT(sp.opportunity_id) AS deals_closed
FROM sales_pipeline sp
WHERE sp.deal_stage = 'Won'
GROUP BY sp.sales_agent
ORDER BY total_closed_value DESC
LIMIT 10;

-- Average Engagement Duration (Days) by Sector

SELECT a.sector,
       AVG(sp.close_date - sp.engage_date) AS avg_days_to_close
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE sp.deal_stage IN ('Won','Lost')
GROUP BY a.sector
ORDER BY avg_days_to_close ASC;

-- Profitability Check: Close Value vs. Product Price

SELECT sp.product,
       AVG(sp.close_value) AS avg_close_value,
       p.sales_price,
       AVG(sp.close_value) - p.sales_price AS avg_profit_margin
FROM sales_pipeline sp
JOIN products p ON sp.product = p.product
WHERE sp.deal_stage = 'Won'
GROUP BY sp.product, p.sales_price
ORDER BY avg_profit_margin DESC;

-- Average close value by year

SELECT DATE_PART('year', close_date) AS year,
       AVG(close_value) AS avg_close_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY year
ORDER BY year;

-- conversion rate by sector 

SELECT a.sector,
       SUM(CASE WHEN sp.deal_stage='Won' THEN 1 ELSE 0 END)::float / COUNT(*) * 100 AS conversion_rate
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
GROUP BY a.sector
ORDER BY conversion_rate DESC;

-- average engagement duration

SELECT AVG(close_date - engage_date) AS avg_days_engagement
FROM sales_pipeline
WHERE deal_stage IN ('Won','Lost');

-- profitability by product 

SELECT p.series,
       AVG(sp.close_value - p.sales_price) AS avg_margin
FROM sales_pipeline sp
JOIN products p ON sp.product = p.product
WHERE sp.deal_stage='Won'
GROUP BY p.series
ORDER BY avg_margin DESC;

-- Regional Office Performance

SELECT st.regional_office,
       AVG(sp.close_value) AS avg_close_value,
       AVG(close_date - engage_date) AS avg_days_engagement
FROM sales_pipeline sp
JOIN sales_teams st ON sp.sales_agent = st.sales_agent
WHERE sp.deal_stage='Won'
GROUP BY st.regional_office
ORDER BY avg_close_value DESC;

--  Average close value by year

SELECT DATE_PART('year', close_date) AS year,
       AVG(close_value) AS avg_close_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY year
ORDER BY year;

-- Average Deal Value by Regional Office

SELECT st.regional_office,
       AVG(sp.close_value) AS avg_deal_value,
       COUNT(sp.opportunity_id) AS total_deals
FROM sales_pipeline sp
JOIN sales_teams st ON sp.sales_agent = st.sales_agent
WHERE sp.deal_stage = 'Won'
GROUP BY st.regional_office
ORDER BY avg_deal_value DESC;


-- Win vs. Loss Ratio by Sector

SELECT a.sector,
       SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals,
       SUM(CASE WHEN sp.deal_stage = 'Lost' THEN 1 ELSE 0 END) AS lost_deals,
       COUNT(sp.opportunity_id) AS total_deals,
       ROUND(SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END)::numeric / COUNT(sp.opportunity_id) * 100, 2) AS win_rate
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
GROUP BY a.sector
ORDER BY win_rate DESC;

-- Average engagement duration by sales agent

SELECT sp.sales_agent,
       AVG(sp.close_date - sp.engage_date) AS avg_days_to_close,
       COUNT(sp.opportunity_id) AS total_deals
FROM sales_pipeline sp
WHERE sp.deal_stage IN ('Won','Lost')
GROUP BY sp.sales_agent
ORDER BY avg_days_to_close ASC;

-- Revenue efficiency

SELECT account,
       revenue,
       employees,
       ROUND(revenue / NULLIF(employees,0), 2) AS revenue_per_employee
FROM accounts
ORDER BY revenue_per_employee DESC
LIMIT 10;

-- Monthly trend of monthly deals

SELECT DATE_TRUNC('month', sp.close_date) AS month,
       COUNT(sp.opportunity_id) AS won_deals,
       SUM(sp.close_value) AS total_value
FROM sales_pipeline sp
WHERE sp.deal_stage = 'Won'
GROUP BY month
ORDER BY month;

-- Join sales_pipeline with accounts 
SELECT sp.opportunity_id, a.sector, sp.close_value FROM sales_pipeline sp JOIN accounts a ON sp.account = a.account;

SELECT p.series,
       AVG(sp.close_value - p.sales_price) AS avg_price_variation
FROM sales_pipeline sp
JOIN products p ON sp.product = p.product
WHERE sp.deal_stage = 'Won'
GROUP BY p.series
ORDER BY avg_price_variation DESC;

CREATE OR REPLACE VIEW crm_fact_table AS
SELECT 
    sp.opportunity_id,
    sp.deal_stage,
    sp.engage_date,
    sp.close_date,
    sp.close_value,

    -- Accounts info
    a.account,
    a.sector,
    a.year_established,
    a.revenue,
    a.employees,
    a.office_location,
    a.subsidiary_of,

    -- Products info
    p.product,
    p.series,
    p.sales_price,

    -- Sales team info
    st.sales_agent,
    st.manager,
    st.regional_office

FROM sales_pipeline sp
LEFT JOIN accounts a ON sp.account = a.account
LEFT JOIN products p ON sp.product = p.product
LEFT JOIN sales_teams st ON sp.sales_agent = st.sales_agent;
















