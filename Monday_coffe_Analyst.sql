-- Monday Coffee SCHEMAS

Select * from sales;
Select * from customers;
Select * from products;
Select * from city;

-- Import Rules
-- 1st import to city
-- 2nd import to products
-- 3rd import to customers
-- 4th import to sales


CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- END of SCHEMAS

-- Report & data analysis

/* Q.1 coffe customer count
how many people in each city are estimated to consume coffe, given that 25% of the population does?
*/

select 
	city_name,
	round((population * 0.25)/1000000, 2) as coffe_consumtion_in_million,
	city_rank
from city
order by 2 desc;

/* Q.2 total revenue from coffe sales
what is the total revenue generated from coffe sales across all cities in the last year quarter year 2023? */

select 
	ci.city_name,
	sum(s.total) as total_revenue
from sales as s
join
	customers as c
on s.customer_id = c.customer_id
join 
	city as ci
on c.city_id = ci.city_id
where 
	extract(year from sale_date) = 2023
	and
	extract(quarter from sale_date) = 4
group by 1
order by 2 desc;


/* Q.3 Sales count for each product 
how many units of each coffe product have been sold? */

select 
	p.product_name,
	count (s.product_id) as total_order
from sales as s
 join 
	products as p
on s.product_id = p.product_id
group by 1
order by 2 desc;

/* Q.4 average sales amount per city
what is the average sales amount per customer in each city? */

select 
	ci.city_name,
	sum(s.total) as total_sales,
	count(distinct c.customer_id) as total_customer,
	round(
		sum(s.total)::numeric/
		count(distinct c.customer_id)::numeric
		, 2) as avg_sale_pr_cs
from sales as s
join 
	customers as c
on s.customer_id = c.customer_id
join 
	city as ci
on c.city_id = ci.city_id
group by 1
order by sum(s.total) desc;


/* Q.5 city population and coffe consumers (25%)
provide a list of cities along with their populations and estimated coffee consumers
return city_name, total current cs, estimated coffe consumers*/

select
	ci.city_name,
	round((ci.population * 0.25)/1000000, 2) as coffe_consumers_in_million,
	count(c.customer_id)
from city as ci
join 
	customers as c
on ci.city_id = c.city_id
group by 1, 2
order by 2 desc;

/* Q.6 top selling product by city
what are the top 3 selling product in each city based on sales volume? */

select *
from 
(
	select
		ci.city_name,
		p.product_name,
		count(s.product_id) as sales_volume,
		dense_rank() over(partition by ci.city_name order by count (s.sale_id) desc) as rank
	from sales as s
	join 
		products as p
	on s.product_id = p.product_id
	join 
		customers as c
	on s.customer_id = c.customer_id
	join 
		city as ci
	on c.city_id = ci.city_id
	group by 1, 2
) as t1
where rank <= 3;


/* Q.7 customer segmentation by city
how many unique customers are there in each city who purchased coffe product? */

select
	ci.city_name,
	count(distinct c.customer_id) as unique_customer
from customers as c
join 
	city as ci
on c.city_id = ci.city_id
join 
	sales as s
on c.customer_id = s.customer_id
join 
	products as p
on s.product_id = p.product_id
where s.product_id in (1, 2, 3, 4, 5, 6, 7 ,8 ,9 ,10, 11, 12, 13, 14)
group by 1
order by 2 desc;


/* Q.8 average sale vs rent
find each city and their average sale per customer anf average rent per customer  */

with city_table
as
(
select 
	ci.city_name,
	count(distinct s.customer_id) as total_customer,
	round(
			sum(s.total)::numeric/
			count(distinct s.customer_id)::numeric
		,2) as avg_sale_per_cs
from sales as s
join 
	customers as c
on s.customer_id = c.customer_id
join 
	city as ci
on c.city_id = ci.city_id
group by 1
order by 1 asc
),
city_rent
as 
(select 
	city_name,
	estimated_rent
from city
)
select
	cr.city_name,
	cr.estimated_rent,
	ct.total_customer,
	ct.avg_sale_per_cs,
	round(cr.estimated_rent::numeric/ct.total_customer::numeric, 2) as avg_rent_per_cs
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 5 desc;


/*Q.9 monthly sales growth
sales growth rate: calculate the percentage growth (or decline) in sales over different time periode (monthly) by each city */
with monthly_sales
as
		(select 
			ci.city_name,
			extract(month from sale_date) as month,
			extract(year from sale_date) as year,
			sum(s.total) as total_Sale
		from sales as s
		join 
			customers as c
		on s.customer_id = c.customer_id
		join 
			city as ci
		on c.city_id = ci.city_id
		group by 1, 2, 3
		order by 1, 3, 2
		),
growth_ratio
as
		(select
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			lag(total_sale, 1) over(partition by city_name order by year, month) as last_month_sale
		from monthly_sales
		)
select 
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	round(
		(cr_month_sale-last_month_sale)::numeric/last_month_Sale::numeric * 100, 2) as growth_ratio
from growth_ratio
where last_month_sale is not null;
	
select * from city;

/*Q.10 market potential analisys
identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffe consumer */
select 
	ci.city_name,
	sum(s.total) as total_revenue,
	ci.estimated_rent as total_rent,
	count(distinct c.customer_id) as total_customer,
	round((ci.population * 0.25)/1000000, 3) as estimated_coffe_consumer_in_million
from city as ci
join 
	customers as c
on ci.city_id = c.city_id
join 
	sales as s
on c.customer_id = s.customer_id
group by 1, 3, 5
order by 2 desc
limit 3;