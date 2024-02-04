-- Cohort LTV:

/*
Data overview:
	1. invoice_no: invoice number. A 6-digit integral number uniquely assigned to each transaction. If this code starts with the letter 'c', it indicates a cancellation;
	2. stock_code: product code. A 5-digit integral number uniquely assigned to each distinct product;
	3. description: product name;
	4. quantity: the quantities of each product per transaction;
	5. invoice_date: invice date and time. The day and time when a transaction was generated;
	6. price: unit price. Product price per unit in sterling;
	7. customer_id: customer number. A 5-digit integral number uniquely assigned to each customer;
	8. country: country name. The name of the country where a customer resides. 
*/

-- View data:
	select * from sales order by invoice_no, customer_id limit 100

-- Exploratory Data Analysis (EDA):
	select * from sales where quantity < 0

	select * from sales where price < 0

	select * from sales where quantity < 0 or price < 0 or invoice_no like 'C%'

	select * from sales where customer_id::int is null

-- Data preparation: aggregation of individual purchases into one customer order:
with sales_data as (
	select 
		invoice_no,
		customer_id::int as customer_id,
		min(invoice_date) as invoice_date,
		sum(price * quantity) as revenue
	from sales
	where invoice_no not like 'C%' and quantity > 0 and price > 0
	group by invoice_no, customer_id::int
	order by customer_id
), 
-- Determination of cohorts, first purchase and number of days between purchases:
cohort_customers as (
	select 
		customer_id,
		invoice_date,
		first_value(to_char(invoice_date, 'YYYY-MM')) over (partition by customer_id order by invoice_date) as cohort,
		extract(days from invoice_date - first_value(invoice_date) over (partition by customer_id order by invoice_date)) as diff_days,
		revenue
	from sales_data
	order by customer_id
)
--Calculation for each cohort:
	-- Number of unique customers;
	-- Maximum number of days between the first and last purchases in a cohort;
	-- Calculation of average revenue in cohorts by day: 0, 30, 60, 90, 180, 300, 400, 500.
select
	cohort,
	count(distinct customer_id) as cnt_customers,
	max(diff_days) as max_diff_days,
	round(sum(case when diff_days = 0 then revenue end) / count(distinct customer_id)) as "0_day",
	round(case when max(diff_days) > 0 then sum(case when diff_days <= 30 then revenue end) / count(distinct customer_id) end) as "30_day",
	round(case when max(diff_days) > 30 then sum(case when diff_days <= 60 then revenue end) / count(distinct customer_id) end) as "60_day",
	round(case when max(diff_days) > 60 then sum(case when diff_days <= 90 then revenue end) / count(distinct customer_id) end) as "90_day",
	round(case when max(diff_days) > 90 then sum(case when diff_days <= 180 then revenue end) / count(distinct customer_id) end) as "180_day",
	round(case when max(diff_days) > 180 then sum(case when diff_days <= 300 then revenue end) / count(distinct customer_id) end) as "300_day",
	round(case when max(diff_days) > 300 then sum(case when diff_days <= 400 then revenue end) / count(distinct customer_id) end) as "400_day",
	round(case when max(diff_days) > 400 then sum(case when diff_days <= 500 then revenue end) / count(distinct customer_id) end) as "500_day"
from cohort_customers
group by cohort
order by cohort