-- ABC:

-- Data overview:
	-- invoice_no: invoice number. A 6-digit integral number uniquely assigned to each transaction. If this code starts with the letter 'c', it indicates a cancellation;
	-- stock_code: product code. A 5-digit integral number uniquely assigned to each distinct product;
	-- description: product name;
	-- quantity: the quantities of each product per transaction;
	-- invoice_date: invice date and time. The day and time when a transaction was generated;
	-- price: unit price. Product price per unit in sterling;
	-- customer_id: customer number. A 5-digit integral number uniquely assigned to each customer;
	-- country: country name. The name of the country where a customer resides. 

-- View data:
	select * from sales order by stock_code limit 100
	
	select count (distinct stock_code) from sales

-- Exploratory Data Analysis (EDA):
	select * from sales where quantity < 0

	select * from sales where price < 0

	select * from sales where quantity < 0 or price < 0 or invoice_no like 'C%'

	select * from sales where customer_id::int is null

-- Data preparation: aggregation of individual purchases into one customer order:
with sales_data as (
	select
	stock_code,
	sum(quantity) as amount,
	round(sum(price * quantity)) as revenue
	from sales
	where invoice_no not like 'C%' and quantity > 0 and price > 0 
	group by stock_code
)
select
	stock_code,
	case
		when sum(amount) over(order by amount desc) / sum(amount) over() <= 0.8 then 'A'
		when sum(amount) over(order by amount desc) / sum(amount) over() <= 0.95 then 'B'
		else 'C'
	end abc_amount,
	case
		when sum(revenue) over(order by revenue desc) / sum(revenue) over() <= 0.8 then 'A'
		when sum(revenue) over(order by revenue desc) / sum(revenue) over() <= 0.95 then 'B'
		else 'C'
	end abc_revenue
from sales_data